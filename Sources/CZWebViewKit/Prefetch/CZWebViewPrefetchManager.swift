import WebKit
import CZUtils
import SwiftUIRedux

class CZWebViewPrefetchManager {
  static let shared = CZWebViewPrefetchManager()
  
  private var prefetchContainerMap = [URL: CZWebViewPrefetchContainer]()
  
  @discardableResult
  func prefetch(url: URL) -> CZWebViewPrefetchContainer {
    let prefetchContainer = prefetchContainerMap[url] ?? CZWebViewPrefetchContainer(url: url)
    prefetchContainer.loadURL(url)
    return prefetchContainer
  }
}
