#if canImport(UIKit)

import UIKit

/**
 Extension for UIImage to facilitate conversion between images and byte arrays.
 */
extension UIImage {
    /**
     Converts the UIImage into an array of RGBA bytes.
     
     - Returns: An optional array of UInt8 values representing the RGBA pixel data.
     */
    @nonobjc public func toByteArrayRGBA() -> [UInt8]? {
        return cgImage?.toByteArrayRGBA()
    }
    
    /**
     Creates a new UIImage from an array of RGBA bytes.
     
     - Parameters:
     - bytes: An array of UInt8 representing the pixel data in RGBA format.
     - width: The width of the image.
     - height: The height of the image.
     - scale: The scale factor of the resulting UIImage.
     - orientation: The image orientation.
     - Returns: A new UIImage instance if successful, otherwise nil.
     */
    @nonobjc public class func fromByteArrayRGBA(_ bytes: [UInt8],
                                                 width: Int,
                                                 height: Int,
                                                 scale: CGFloat = 0,
                                                 orientation: UIImage.Orientation = .up) -> UIImage? {
        if let cgImage = CGImage.fromByteArrayRGBA(bytes, width: width, height: height) {
            return UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        } else {
            return nil
        }
    }
    
    /**
     Creates a new UIImage from an array of grayscale bytes.
     
     - Parameters:
     - bytes: An array of UInt8 representing the pixel data in grayscale format.
     - width: The width of the image.
     - height: The height of the image.
     - scale: The scale factor of the resulting UIImage.
     - orientation: The image orientation.
     - Returns: A new UIImage instance if successful, otherwise nil.
     */
    @nonobjc public class func fromByteArrayGray(_ bytes: [UInt8],
                                                 width: Int,
                                                 height: Int,
                                                 scale: CGFloat = 0,
                                                 orientation: UIImage.Orientation = .up) -> UIImage? {
        if let cgImage = CGImage.fromByteArrayGray(bytes, width: width, height: height) {
            return UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        } else {
            return nil
        }
    }
}

#endif
