import UIKit
import WebKit

class BlazeWebView: NSObject, WKScriptMessageHandler {

    private var webView: WKWebView!
    private var isWebViewReady: Bool = false
    private var consumingBackPress: Bool = false
    private var eventQueue: [String: [String: Any]] = [:]
    private var context: UIViewController
    private var initiatePayload: [String: Any]
    private var callbackFn: ([String: Any]) -> Void

    init(
        context: UIViewController, initiatePayload: [String: Any],
        callbackFn: @escaping ([String: Any]) -> Void
    ) {
        self.context = context
        self.initiatePayload = initiatePayload
        self.callbackFn = callbackFn
        super.init()

        let contentController = WKUserContentController()
        contentController.add(self, name: "Native")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.navigationDelegate = self

        if let url = URL(string: getBaseUrl(payload: initiatePayload)) {
            self.webView.load(URLRequest(url: url))
        }

        self.sendEvent(event: "initiate", payload: initiatePayload)
    }

    func process(payload: [String: Any]) {
        self.sendEvent(event: "process", payload: payload)
    }

    func terminate() {
        self.sendEvent(event: "terminate", payload: [:])
        self.webView.removeFromSuperview()
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
            isWebViewReady = true
            drainEventQueue()
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
    }

    private func sendEvent(event: String, payload: [String: Any]) {

        let eventMessage: [String: Any] = [
            "eventName": event,
            "eventData": payload,
            "source": "blaze",
        ]

        if isWebViewReady {
            let jsonData = try? JSONSerialization.data(
                withJSONObject: eventMessage)
            let jsonString = String(data: jsonData!, encoding: .utf8)!
            self.webView.evaluateJavaScript(
                "onSDKEvent(JSON.stringify(\(jsonString)))")
        } else {
            eventQueue[event] = payload
        }
    }

    private func drainEventQueue() {
        let pendingEvents = eventQueue
        eventQueue.removeAll()
        for (event, payload) in pendingEvents {
            sendEvent(event: event, payload: payload)
        }
    }

    private func renderView() {
        self.webView.frame = self.context.view.bounds
        self.context.view.addSubview(self.webView)
    }

    private func hideView() {
        self.webView.removeFromSuperview()
    }
}

extension BlazeWebView: WKNavigationDelegate {
    // Implement WKNavigationDelegate methods if needed
}
