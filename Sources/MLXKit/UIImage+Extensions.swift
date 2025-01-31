#if canImport(UIKit)

import UIKit

extension UIImage {
  /**
    Resizes the image.

    - Parameter scale: If this is 1, `newSize` is the size in pixels.
  */
  @nonobjc public func resized(to newSize: CGSize, scale: CGFloat = 1) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = scale
    let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
    let image = renderer.image { _ in
      draw(in: CGRect(origin: .zero, size: newSize))
    }
    return image
  }

  /**
    Rotates the image around its center.

    - Parameter degrees: Rotation angle in degrees.
    - Parameter keepSize: If true, the new image has the size of the original
      image, so portions may be cropped off. If false, the new image expands
      to fit all the pixels.
  */
  @nonobjc public func rotated(by degrees: CGFloat, keepSize: Bool = true) -> UIImage {
    let radians = degrees * .pi / 180
    let newRect = CGRect(origin: .zero, size: size).applying(CGAffineTransform(rotationAngle: radians))

    // Trim off the extremely small float value to prevent Core Graphics from rounding it up.
    var newSize = keepSize ? size : newRect.size
    newSize.width = floor(newSize.width)
    newSize.height = floor(newSize.height)

    return UIGraphicsImageRenderer(size: newSize).image { rendererContext in
      let context = rendererContext.cgContext
      context.setFillColor(UIColor.black.cgColor)
      context.fill(CGRect(origin: .zero, size: newSize))
      context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
      context.rotate(by: radians)
      let origin = CGPoint(x: -size.width / 2, y: -size.height / 2)
      draw(in: CGRect(origin: origin, size: size))
    }
  }
}

#endif
