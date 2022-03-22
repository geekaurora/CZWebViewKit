import WebKit
import CZUtils
import SwiftUIRedux

class CZWebViewPrefetchContainer: NSObject {
  private var url: URL?
  private(set) var webView: WKWebView?
  
  init(url: URL?) {
    self.url = url
  }
}
