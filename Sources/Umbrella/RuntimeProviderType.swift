import Foundation

public protocol RuntimeProviderType: ProviderType {
  associatedtype Parameters = [String: Any]
  
  var className: String { get }
  var instanceSelectorName: String? { get } // optional
  var selectorName: String { get }
  
  func mapParameters(_ parameters: [String: Any]) -> Parameters?
}

public extension RuntimeProviderType where Parameters == [String: Any] {
  func mapParameters(_ parameters: [String: Any]) -> Parameters? {
    return parameters
  }
}

public extension RuntimeProviderType {
  var cls: NSObject.Type? {
    return NSClassFromString(self.className) as? NSObject.Type
  }

  var instanceSelectorName: String? {
    return nil
  }

  var instance: AnyObject? {
    guard let cls = self.cls else { return nil }
    guard let sel = self.instanceSelectorName.flatMap(NSSelectorFromString) else { return nil }
    guard cls.responds(to: sel) else { return nil }
    return cls.perform(sel)?.takeUnretainedValue()
  }

  var selector: Selector {
    return NSSelectorFromString(self.selectorName)
  }

  var responds: Bool {
    guard let cls = self.cls else { return false }
    if let instance = self.instance {
      return instance.responds(to: self.selector)
    } else {
      return cls.responds(to: self.selector)
    }
  }

  func log(_ eventName: String, parameters: [String: Any]?) {
    guard self.responds else { return }
    let parameters = parameters.flatMap(mapParameters)
    if let instance = self.instance {
      _ = instance.perform(self.selector, with: eventName, with: parameters)
    } else {
      _ = self.cls?.perform(self.selector, with: eventName, with: parameters)
    }
  }
}
