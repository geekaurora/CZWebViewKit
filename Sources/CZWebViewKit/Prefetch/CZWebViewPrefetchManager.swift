import WebKit
import CZUtils
import SwiftUIRedux

class CZWebViewPrefetchManager {
  static let shared = CZWebViewPrefetchManager()
  
  private var prefetchContainerMap = [URL: CZWebViewPrefetchContainer]()
  
  @discardableResult
  func prefetch(url: URL) -> CZWebViewPrefetchContainer {
    let prefetchContainer: CZWebViewPrefetchContainer = {
      // TODO: Reuse prefetchContainer after fix crash.
//      if let prefetchContainer = prefetchContainerMap[url] {
//        return prefetchContainer
//      }
      return CZWebViewPrefetchContainer(url: url)
    }()
    prefetchContainerMap[url] = prefetchContainer
    
    prefetchContainer.loadURL(url)
    return prefetchContainer
  }
}
