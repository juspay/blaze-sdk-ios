import WebKit

enum WebViewHardening {

    static func apply(to configuration: WKWebViewConfiguration) {
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.dataDetectorTypes = []
    }

    static func apply(to webView: WKWebView) {
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = false
        if #available(iOS 16.4, *) {
            webView.isInspectable = false
        }
    }
}
