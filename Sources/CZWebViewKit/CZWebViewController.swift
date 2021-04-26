import Combine
import WebKit
import CZUtils
import SwiftUIRedux

/// Delegate that gets notified when the web view state updates.
public protocol CZWebViewControllerDelegate: class {
  func webViewDidFinishLoading(html: String?, error: Error?)
}

/**
 ### Usage
 ```
 /// Load reomote URL.
 loadURL(_ url: URL?)
 
 /// Load local file URL.
 loadFileURL(_ url: URL?)
 
 /// Load HTML String.
 loadHTMLString(_ string: String, baseURL: URL?)
 ```
 */
public class CZWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
  private var navigationBarType: CZWebViewNavigationBarType
  private var shouldPopupWhenTapLink: Bool
  private var initialHostName: String?
  private var showLoadingProgress: Bool
  
  public var delegate: CZWebViewControllerDelegate?
  
  public private(set) lazy var webView: WKWebView = {
    let config = WKWebViewConfiguration()
    let userContentController = WKUserContentController()
    // Bridging message channel to native.
    userContentController.add(self, name: "test")
    config.userContentController = userContentController
    let webView = WKWebView(frame: .zero, configuration: config)
    
    webView.uiDelegate = self
    webView.navigationDelegate = self
    return webView
  }()
  
  private var progressView: UIProgressView?

  private lazy var goBackButtonItem: UIBarButtonItem = {
    let chevronLeft = UIImage(systemName: "chevron.left")
    let buttonItem = UIBarButtonItem(image: chevronLeft, style: .plain, target: webView, action: #selector(webView.goBack))
    buttonItem.isEnabled = webView.canGoBack
    return buttonItem
  }()
  
  private lazy var goForwardButtonItem: UIBarButtonItem = {
    let chevronLeft = UIImage(systemName: "chevron.right")
    let buttonItem = UIBarButtonItem(image: chevronLeft, style: .plain, target: webView, action: #selector(webView.goForward))
    buttonItem.isEnabled = webView.canGoBack
    return buttonItem
  }()
  
  private lazy var cancelBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelBarButtonItemTapped))
  @objc func cancelBarButtonItemTapped() {
    self.navigationController?.popViewController(animated: true)
  }
  
  private lazy var refreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshBarButtonItemTapped))
  
  @objc func refreshBarButtonItemTapped() {
    webView.reload()
  }
  
  private var url: URL?
  private var observers: [NSKeyValueObservation] = []
  
  public init(url: URL? = nil,
              navigationBarType: CZWebViewNavigationBarType = .none,
              shouldPopupWhenTapLink: Bool = true,
              showLoadingProgress: Bool = true) {
    self.url = url
    self.navigationBarType = navigationBarType
    self.shouldPopupWhenTapLink = shouldPopupWhenTapLink
    self.showLoadingProgress = showLoadingProgress
    super.init(nibName: nil, bundle: .main)
  }
  
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  
  public override func loadView() {
    view = webView
    initSubviews()
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  private func initSubviews() {
    setupObservers()
    loadURL(self.url)
    
    // ProgressView.
    if showLoadingProgress {
      progressView = UIProgressView(progressViewStyle: .default)
      webView.addSubview(progressView!)
      NSLayoutConstraint.activate([
        progressView!.alignHorizontally(to: webView),
        progressView!.alignTop(to: webView, constant: 45)
      ])
    }
    
    // NavigationItems.
    switch navigationBarType {
    case .web:
      navigationItem.setLeftBarButtonItems([goBackButtonItem, goForwardButtonItem], animated: false)
      navigationItem.setRightBarButton(refreshBarButtonItem, animated: false)
    case .system:
      navigationItem.backBarButtonItem = UIBarButtonItem(
        title: "",
//        image: UIImage(systemName: "chevron.left"),
        style: .plain,
        target: nil,
        action: nil)
      break
    default:
      break
    }
  }
  
  // MARK: - Load URL
  
  /// Load remote URL.
  public func loadURL(_ url: URL?) {
    guard let url = url else {
      return
    }
    self.url = url
    webView.load(URLRequest(url: url))
  }
  
  /// Load local file URL.
  public func loadFileURL(_ url: URL?) {
    guard let url = url.assertIfNil else {
      return
    }
    self.url = url
    webView.loadFileURL(url, allowingReadAccessTo: url)
  }
  
  /// Load HTML String.
  public func loadHTMLString(_ string: String, baseURL: URL?) {
    webView.loadHTMLString(string, baseURL: baseURL)
  }
  
  deinit {
    observers.forEach {
      $0.invalidate()
    }
  }
}

// MARK: - Bridging: Native to Web

private extension CZWebViewController {
  /**
   Inject js - Execute code from Native to Web: Inject stringify javascript String.
   */
  private func injectJavascript() {
    let contentController = WKUserContentController()
    let scriptSource = "document.body.style.backgroundColor = `red`;"
    let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    contentController.addUserScript(script)
    
    let config = WKWebViewConfiguration()
    config.userContentController = contentController
    webView = WKWebView(frame: .zero, configuration: config)
  }
}

// MARK: - WKScriptMessageHandler - Bridging: Web to Native

extension CZWebViewController: WKScriptMessageHandler {
  /**
   Handle message from javascript.
   Run: load test.htm with CZWebViewController.
   */
  public func userContentController(_ userContentController: WKUserContentController,
                                    didReceive message: WKScriptMessage) {
    dbgPrint("[Core] \(#function) - received script message: \(message)")
    
    // iOS/Web Bridging: message/Action from Web.
    if message.name == "test",
      let messageBody = (message.body as? [String: Any]).assertIfNil {
      
      if let actionType = messageBody["type"] as? String {
        let action = WebToIOSAction(
          type: actionType,
          payload: messageBody["payload"] as! CZDictionary)
        // Redux: dispatch iOS/Web bridging Action with type/dict.
        ReduxRootStore.shared.dispatch(action: action)
      }      
      print("[Core] Received WKScriptMessageHandler Message = \(messageBody)")
    }
  }
}

// MARK: - WKNavigationDelegate

public extension CZWebViewController {
  func webView(_ webView: WKWebView,
               decidePolicyFor navigationAction: WKNavigationAction,
               decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if initialHostName == nil {
      initialHostName = navigationAction.request.url?.host
    }
    dbgPrint("[Core] \(#function) - navigationAction.request.url = \(navigationAction.request.url)")
    
    let shouldPresentLink = (shouldPopupWhenTapLink && navigationAction.request.url?.host != initialHostName)
    
    // TODO: Fix bug push multi times when load url - sub pages?
    // Push to navigationController - native experience of navigationControlle, instead of Web.
    // let shouldPushLink = (navigationAction.request.url != self.url && navigationController != nil)
    let shouldPushLink = false
    
    if shouldPresentLink {
      // Present for the different host.
      CZWebViewNavigationController.present(url: navigationAction.request.url)
      decisionHandler(.cancel)
    } else if shouldPushLink {
      // Push for the same host.
      CZWebViewNavigationController.pushWebViewController(
        url: navigationAction.request.url,
        navigationBarType: navigationBarType,
        shouldPopupWhenTapLink: shouldPopupWhenTapLink,
        navigationController: navigationController)
      decisionHandler(.cancel)
    } else {
      decisionHandler(.allow)
    }
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    if navigationBarType == .web {
      title = webView.title
    }
  }  
}

// MARK: - WKUIDelegate

public extension CZWebViewController {
  /**
   Force all popup windows to remain in the current WKWebView.
   By default, WKWebView is blocking new windows from being created
   ex <a href="link" target="_blank">text</a>.
   This code catches those popup windows and displays them in the current WKWebView.
   */
  func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    
    // open in current view
    webView.load(navigationAction.request)
    
    // don't return a new view to build a popup into (the default behavior).
    return nil;
  }
  
  func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
    CZAlertManager.showAlert(message: message)
    completionHandler()
  }
}

// MARK: - Private Methods

extension CZWebViewController {
  
  public override func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey : Any]?,
                                    context: UnsafeMutableRawPointer?) {
    switch (keyPath) {
    case #keyPath(WKWebView.isLoading):
      print("webView.isLoading = \(webView.isLoading)")
      progressView?.isHidden = !webView.isLoading
      
      // Read HTML from WebView.
      if !webView.isLoading {
        webView.evaluateJavaScript(
          "document.body.innerHTML",                              // HTML: excludes tag
          // "document.documentElement.outerHTML.toString()",     // HTML: includes tag
          completionHandler: { [weak self] (html: Any?, error: Error?) in
            self?.delegate?.webViewDidFinishLoading(html: html as? String, error: error)
          })
      }
      
    case #keyPath(WKWebView.estimatedProgress):
      progressView?.progress = Float(webView.estimatedProgress)
    case #keyPath(WKWebView.canGoBack):
      print("canGoBack")
      goBackButtonItem.isEnabled = webView.canGoBack
    case #keyPath(WKWebView.canGoForward):
      print("canGoForward")
      goForwardButtonItem.isEnabled = webView.canGoForward
    default:
      break
    }
  }
  
  func setupObservers() {
    view.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: [.old, .new], context: nil)
    view.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    view.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
    view.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
    
    view.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: .new, context: nil)
    view.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward), options: .new, context: nil)
    
    //    func subscriber<Value>(for keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
    //      return webView.observe(keyPath, options: [.prior]) { _, change in
    //        if change.isPrior {
    //          // Dispatches when property changes.
    //          //          self.objectWillChange.send()
    //        }
    //      }
    //    }
    //
    //    // Setup observers for all KVO compliant properties
    //    observers = [
    //      subscriber(for: \.canGoBack),
    //      subscriber(for: \.canGoForward)
    //      //
    //      //      subscriber(for: \.title),
    //      //      subscriber(for: \.url),
    //      //      subscriber(for: \.isLoading),
    //            subscriber(for: \.estimatedProgress),
    //      //      subscriber(for: \.hasOnlySecureContent),
    //      //      subscriber(for: \.serverTrust),
    //    ]
  }
}
