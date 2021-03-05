import SwiftUIKit
import SwiftUIRedux
import Combine
import CZUtils

/**
 Action from Web to Native.
 */
public class WebToIOSAction: ReduxActionProtocol, CustomStringConvertible {
  public var type: String
  public var payload: CZDictionary?
  public static let defaultType = "default"
  
  public init(type: String = WebToIOSAction.defaultType,
              payload: CZDictionary? = nil) {
    self.type = type
    self.payload = payload
  }
  
  // MARK: - CustomStringConvertible
  
  public var description: String {
    let dict: CZDictionary = [
      "type": type,
      "payload": payload ?? [:]
    ]
    return dict.prettyDescription
  }
}

/**
Action from Native to Web.
*/
public class IOSToWebAction: WebToIOSAction {}
