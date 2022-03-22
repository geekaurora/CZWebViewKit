import WebKit
import CZUtils
import SwiftUIRedux

class CZWebViewPrefetchContainer: NSObject {
  private var url: URL?
  private(set) var webView: WKWebView
  
  init(url: URL?) {
    self.url = url
    
    self.webView = CZWebViewFactory.createWebView(
      scriptMessageHandler: nil,
      uiDelegate: nil,
      navigationDelegate: nil)
  }
  
  /// Load remote URL.
  func loadURL(_ url: URL? = nil) {
    guard let url = (url ?? self.url).assertIfNil else {
      return
    }
    self.url = url
    CZPerfTracker.shared.endTracking(event: "CZWebViewController_BeforeRequest")
    webView.load(URLRequest(url: url))
  }
}
