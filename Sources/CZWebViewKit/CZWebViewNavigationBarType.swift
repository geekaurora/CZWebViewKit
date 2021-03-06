import Foundation

/**
 The types of NavigationBar.
*/
public enum CZWebViewNavigationBarType: Equatable {
  /// Without NavigationBar.
  case none
  /// NavigationBar with Web style. e.g. go forward/back etc.
  case web
  /// NavigationBar with iOS style.
  case system
}
