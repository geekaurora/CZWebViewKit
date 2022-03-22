import WebKit
import CZUtils

/**
 NavigationController that maintains the underlying WebViewController.
*/
public class CZWebViewNavigationController: UIViewController {
  
  /// Returns the top most webViewController in `navigationViewController`.
  public var webViewController: CZWebViewController {
    let topMostViewController = (navigationViewController?.viewControllers.last as? CZWebViewController) ?? _webViewController
    return topMostViewController
  }
  
  private var _webViewController: CZWebViewController
  private var navigationViewController: UINavigationController?
  private var navigationBarType: CZWebViewNavigationBarType
  private var shouldPopupWhenTapLink: Bool

  public init(url: URL? = nil,
              injectedWebView: WKWebView? = nil,
              navigationBarType: CZWebViewNavigationBarType = .none,
              shouldPopupWhenTapLink: Bool = true) {
    self.navigationBarType = navigationBarType
    self.shouldPopupWhenTapLink = shouldPopupWhenTapLink
    self._webViewController = CZWebViewController(
      url: url,
      injectedWebView: injectedWebView,
      navigationBarType: navigationBarType,
      shouldPopupWhenTapLink: shouldPopupWhenTapLink)
    super.init(nibName: nil, bundle: .main)
  }
  
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  
  public static func present(url: URL? = nil,
                             injectedWebView: WKWebView? = nil,
                             //navigationBarType: CZWebViewNavigationBarType = .none,
                             navigationBarType: CZWebViewNavigationBarType = .web,
                             shouldPopupWhenTapLink: Bool = false) {
    let webViewNavigationController = CZWebViewNavigationController(
      url: url,
      injectedWebView: injectedWebView,
      navigationBarType:navigationBarType,
      shouldPopupWhenTapLink: shouldPopupWhenTapLink)
    UIViewController.topMost()?.present(webViewNavigationController, animated: true, completion: nil)
  }
  
  public static func pushWebViewController(url: URL?,
                                           navigationBarType: CZWebViewNavigationBarType,
                                           shouldPopupWhenTapLink: Bool,
                                           navigationController: UINavigationController?) {
    // Not show loading progress in pushed controller.
    let webViewController = CZWebViewController(
      url: url,
      navigationBarType: navigationBarType,
      shouldPopupWhenTapLink: shouldPopupWhenTapLink,
      showLoadingProgress: false)
    navigationController?.pushViewController(webViewController, animated: true)
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    initSubviews()
  }
  
  public func loadURL(_ url: URL?) {
    webViewController.loadURL(url)
  }
  
  public func loadFileURL(_ url: URL?) {
    webViewController.loadFileURL(url)
  }
  
  public func loadHTMLString(_ string: String, baseURL: URL?) {
    webViewController.loadHTMLString(string, baseURL: baseURL)
  }
  
  public override func loadView() {
    view = UIView()
  }
}

// MARK: - Private methods

private extension CZWebViewNavigationController{
  func initSubviews() {
    if navigationBarType != .none {
      navigationViewController = UINavigationController(rootViewController: _webViewController)
      navigationViewController?.overlayOnSuperViewController(self)
    } else {
      _webViewController.overlayOnSuperViewController(self)
    }
  }
}
