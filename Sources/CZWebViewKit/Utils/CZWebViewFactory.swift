import WebKit
import CZUtils

/// Factory that builds WKWebView supporting bridgemessages from javascript to the native.
class CZWebViewFactory {
  static func createWebView(config: WKWebViewConfiguration = WKWebViewConfiguration(),
                            scriptMessageHandler: WKScriptMessageHandler? = nil,
                            uiDelegate: WKUIDelegate? = nil,
                            navigationDelegate: WKNavigationDelegate? = nil) -> WKWebView {
    if let scriptMessageHandler = scriptMessageHandler {
      // Bridging message channel to the native.
      let userContentController = WKUserContentController()
      userContentController.add(scriptMessageHandler, name: "test")
      config.userContentController = userContentController
    }
    
    let webView = WKWebView(frame: .zero, configuration: config)
    webView.uiDelegate = uiDelegate
    webView.navigationDelegate = navigationDelegate
    return webView
  }
}
