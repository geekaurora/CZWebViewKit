import WebKit
import CZUtils
import SwiftUIRedux

class CZWebViewPrefetchManager {
  static let shared = CZWebViewPrefetchManager()
  
  private var prefetchContainerMap = [URL: CZWebViewPrefetchContainer]()
  
  func prefetch(url: URL?) {
    guard let url = url else {
      return
    }
    let prefetchContainer = prefetchContainerMap[url] ?? CZWebViewPrefetchContainer(url: url)
  }
}
