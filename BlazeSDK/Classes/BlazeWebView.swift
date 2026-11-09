import UIKit
import WebKit

private class SafeAreaWebView: WKWebView {

    var onSafeAreaChange: (() -> Void)?

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        onSafeAreaChange?()
    }
}

class BlazeWebView: NSObject, WKScriptMessageHandler {

    private var webView: SafeAreaWebView!
    private var isWebViewReady: Bool = false
    private var consumingBackPress: Bool = false
    private var eventQueue: [String: [String: Any]] = [:]
    private var context: UIViewController
    private weak var container: UIView?
    private var initiatePayload: [String: Any]
    private var callbackFn: ([String: Any]) -> Void
    private var isTerminated: Bool = false
    private var lastSafeMargin: SafeMargin?
    private var initiateFailure: FrameFailure?
    private var frame: FrameConfig

    init(
        context: UIViewController, initiatePayload: [String: Any],
        container: UIView?,
        callbackFn: @escaping ([String: Any]) -> Void
    ) {
        self.context = context
        self.initiatePayload = initiatePayload
        self.container = container
        self.callbackFn = callbackFn
        self.frame = FrameConfig.from(payload: initiatePayload)
        super.init()

        let contentController = WKUserContentController()
        contentController.add(self, name: "Native")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        WebViewHardening.apply(to: config)

        self.webView = SafeAreaWebView(frame: .zero, configuration: config)
        self.webView.navigationDelegate = self
        WebViewHardening.apply(to: self.webView)
        self.webView.uiDelegate = self
        self.webView.scrollView.contentInsetAdjustmentBehavior = .never
        self.webView.onSafeAreaChange = { [weak self] in
            self?.sendSafeMarginIfChanged()
        }
        self.webView.isOpaque = false
        self.webView.backgroundColor = .clear
        self.webView.scrollView.backgroundColor = .clear

        self.sendEvent(event: "initiate", payload: initiatePayload)
        self.loadFrame()
    }

    private func loadFrame() {
        BlazeConfig.shared.resolveFrame(
            service: getService(payload: initiatePayload),
            environment: getEnvironment(payload: initiatePayload)
        ) { [weak self] remote in
            guard let self = self, !self.isTerminated else {
                return
            }
            self.renderFrame(remote)
        }
    }

    private func renderFrame(_ remote: RemoteFrame?) {
        var resolved: FrameConfig?
        if let remote = remote {
            if let origins = remote.allowedOrigins {
                resolved = remote.frameUrl.flatMap { FrameConfig.locked(frameUrl: $0, origins: origins) }
            } else {
                resolved = FrameConfig(defaultUrl: remote.frameUrl ?? frame.defaultUrl, allowedOrigins: nil)
            }
        }
        guard let frame = resolved else {
            initiateFailure = remote?.frameUrl == nil ? .configUnavailable : .invalidAllowedOrigin
            reportError(
                eventName: "initiate", requestId: initiatePayload["requestId"] as? String ?? "")
            return
        }
        self.frame = frame
        guard let url = URL(string: frame.defaultUrl) else {
            return
        }
        webView.load(URLRequest(url: url))
    }

    private func reportError(eventName: String, requestId: String) {
        let response: [String: Any] = [
            "requestId": requestId,
            "service": getService(payload: initiatePayload),
            "payload": [
                "eventName": eventName,
                "error": true,
                "errorCode": initiateFailure?.code ?? "",
                "errorSource": "sdk",
                "errorDetails": initiateFailure?.details ?? "",
            ],
        ]
        DispatchQueue.main.async {
            self.callbackFn(response)
        }
    }

    func process(payload: [String: Any]) {
        if initiateFailure != nil {
            reportError(eventName: "process", requestId: payload["requestId"] as? String ?? "")
            return
        }
        self.sendEvent(event: "process", payload: payload)
    }

    func terminate() {
        self.sendEvent(event: "terminate", payload: [:])
        self.isTerminated = true
        DispatchQueue.main.async {
            self.webView.stopLoading()
            self.webView.configuration.userContentController.removeScriptMessageHandler(forName: "Native")
            self.webView.removeFromSuperview()
            self.clearOriginData()
        }
    }

    private func clearOriginData() {
        guard let origins = frame.allowedOrigins else {
            return
        }
        let hosts = origins.compactMap { URL(string: $0)?.host?.lowercased() }
        let store = webView.configuration.websiteDataStore
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        store.fetchDataRecords(ofTypes: types) { records in
            let ours = records.filter { record in
                let name = record.displayName.lowercased()
                return hosts.contains { $0 == name || $0.hasSuffix("." + name) }
            }
            store.removeData(ofTypes: types, for: ours) {}
        }
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {

        guard let event = message.body as? String else { return }
        let eventJson = safeParseJson(jsonString: event)

        let eventName = eventJson["eventName"] as? String ?? ""
        let eventData = eventJson["eventData"] as? String ?? ""
        let eventDataJson = safeParseJson(jsonString: eventData)

        if eventName == "appReady" {
            sendInitiate()
        }
        if eventName == "callbackEvent" {
            self.callbackFn(eventDataJson)
        }
        if eventName == "consumeBackPress" {
            consumingBackPress = true
        }
        if eventName == "releaseBackPress" {
            consumingBackPress = false
        }
        if eventName == "renderView" {
            renderView()
        }
        if eventName == "hideView" {
            hideView()
        }
        if eventName == "invokeMethod" {
            handleInvokeMethod(eventDataJson)
        }
    }

    private func sendEvent(event: String, payload: [String: Any]) {

        let eventMessage: [String: Any] = [
            "eventName": event,
            "eventData": payload,
            "source": "blaze",
        ]

        runOnMain {
            if self.isWebViewReady {
                let jsonData = try? JSONSerialization.data(
                    withJSONObject: eventMessage)
                let jsonString = String(data: jsonData!, encoding: .utf8)!
                self.webView.evaluateJavaScript(
                    "onSDKEvent(JSON.stringify(\(jsonString)))")
            } else {
                self.eventQueue[event] = payload
            }
        }
    }

    private func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    private func drainEventQueue() {
        let pendingEvents = eventQueue
        eventQueue.removeAll()
        for (event, payload) in pendingEvents {
            sendEvent(event: event, payload: payload)
        }
    }

    private func sendInitiate() {
        if isTerminated {
            return
        }
        let safeMargin = getSafeMargin()
        lastSafeMargin = safeMargin
        if var initiate = eventQueue["initiate"], var payload = initiate["payload"] as? [String: Any] {
            payload["_sdkParams"] = SdkParams(safeMargin: safeMargin).toJson()
            initiate["payload"] = payload
            eventQueue["initiate"] = initiate
        }
        isWebViewReady = true
        drainEventQueue()
    }

    private func sendSafeMarginIfChanged() {
        if isTerminated || lastSafeMargin == nil {
            return
        }
        let safeMargin = getSafeMargin()
        if safeMargin != lastSafeMargin {
            lastSafeMargin = safeMargin
            sendEvent(event: "_sdkParams", payload: SdkParams(safeMargin: safeMargin).toJson())
        }
    }

    private func getContainer() -> UIView {
        return self.container ?? self.context.view.window ?? self.context.view
    }

    private func renderView() {
        DispatchQueue.main.async {
            if self.container == nil && self.context.view.window == nil {
                print("BlazeSDK: host view has no window, falling back to the view controller's view.")
            }
            let host = self.getContainer()

            self.webView.frame = host.bounds
            self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            host.addSubview(self.webView)
        }
    }

    private func getSafeMargin() -> SafeMargin {
        let view: UIView = self.webView.window != nil ? self.webView : getContainer()
        let insets = view.safeAreaInsets
        return SafeMargin(
            top: Int(insets.top.rounded()),
            right: Int(insets.right.rounded()),
            bottom: Int(insets.bottom.rounded()),
            left: Int(insets.left.rounded())
        )
    }

    private func hideView() {
        DispatchQueue.main.async {
            self.webView.removeFromSuperview()
            self.webView.frame = .zero
        }
    }

    func openApp(payload: String) -> String {
        if let appURL = URL(string: payload),
            UIApplication.shared.canOpenURL(appURL)
        {
            UIApplication.shared.open(appURL, options: [:])
        }
        return "unknonw"
    }

    private func getFromStorage(key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }

    private func canOpen(payload: String) -> Bool {
        if let appURL = URL(string: payload) {
            return UIApplication.shared.canOpenURL(appURL)
        }
        return false
    }

    private func saveToStorage(key: String, value: String) -> Bool {
        UserDefaults.standard.set(value, forKey: key)
        return true
    }

    private func handleInvokeMethod(_ eventData: [String: Any]) {
        guard let methodName = eventData["methodName"] as? String,
            let requestId = eventData["requestId"] as? String,
            let params = eventData["params"] as? String
        else {
            return
        }

        let paramsJson = safeParseJson(jsonString: params)

        var invokeResult: [String: Any] = [
            "requestId": requestId, "methodName": methodName,
        ]

        switch methodName {
        case "saveToStorage" where !frame.isRestricted:
            if let key = paramsJson["key"] as? String,
                let value = paramsJson["value"] as? String
            {
                invokeResult["methodResult"] = saveToStorage(
                    key: key, value: value)
            }
        case "openApp" where !frame.isRestricted:
            if let intentUri = paramsJson["intentUri"] as? String {
                invokeResult["methodResult"] = openApp(payload: intentUri)
            }
        case "getFromStorage" where !frame.isRestricted:
            if let key = paramsJson["key"] as? String {
                let value = getFromStorage(key: key)
                invokeResult["methodResult"] = ["key": key, "value": value]
            }
        case "canOpen":
            if let payload = paramsJson["payload"] as? String {
                invokeResult["methodResult"] = canOpen(payload: payload)
            }
        default:
            invokeResult["methodResult"] = "Method not found"
        }

        sendEvent(event: "invokeMethodResult", payload: invokeResult)
    }

}

extension BlazeWebView: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(frame.isRestricted ? .cancel : .allow)
            return
        }

        if isUPIIntentUri(url), canOpen(payload: url.absoluteString) {
            let _ = openApp(payload: url.absoluteString)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(frame.decide(url) == .allow ? .allow : .cancel)
    }
}

extension BlazeWebView: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = navigationAction.request.url else {
            return nil
        }
        if isUPIIntentUri(url), canOpen(payload: url.absoluteString) {
            let _ = openApp(payload: url.absoluteString)
        }
        return nil
    }

    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.deny)
    }
}
