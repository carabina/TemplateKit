//
//  Image.swift
//  TemplateKit
//
//  Created by Matias Cudich on 9/3/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation

public struct ImageProperties: ViewProperties {
  public var key: String?
  public var layout: LayoutProperties?
  public var style: StyleProperties?
  public var gestures: GestureProperties?

  public var contentMode = UIViewContentMode.scaleAspectFit
  public var url: URL?
  public var name: String?

  public init(_ properties: [String : Any]) {
    applyProperties(properties)

    if let contentMode: UIViewContentMode = properties.get("contentMode") {
      self.contentMode = contentMode
    }
    url = properties.get("url")
    name = properties.get("name")
  }
}

public func ==(lhs: ImageProperties, rhs: ImageProperties) -> Bool {
  return lhs.contentMode == rhs.contentMode && lhs.url == rhs.url && lhs.name == rhs.name && lhs.equals(otherViewProperties: rhs)
}

public class Image: UIImageView, NativeView {
  public static var propertyTypes: [String: ValidationType] {
    return commonPropertyTypes.merged(with: [
      "url": Validation.url,
      "name": Validation.string,
      "contentMode": ImageValidation.contentMode
    ])
  }

  public var eventTarget: AnyObject?

  public var properties = ImageProperties([:]) {
    didSet {
      applyCommonProperties(properties: properties)
      applyImageProperties(properties: properties)
    }
  }

  public required init() {
    super.init(frame: CGRect.zero)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func applyProperties(properties: ImageProperties) {
    applyCommonProperties(properties: properties)
    applyImageProperties(properties: properties)
  }

  func applyImageProperties(properties: ImageProperties) {
    contentMode = properties.contentMode

    if let url = properties.url {
      ImageService.shared.load(url) { [weak self] result in
        switch result {
        case .success(let image):
          DispatchQueue.main.async {
            self?.image = image
          }
        case .failure(_):
          // TODO(mcudich): Show placeholder error image.
          break
        }
      }
    } else if let name = properties.name {
      image = UIImage(named: name)
    }
  }
}