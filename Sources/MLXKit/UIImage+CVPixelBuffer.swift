#if canImport(UIKit)

import UIKit
import VideoToolbox

extension UIImage {
    /// Converts the image to an ARGB `CVPixelBuffer`.
    /// - Returns: An optional `CVPixelBuffer` in ARGB format.
    public func pixelBuffer() -> CVPixelBuffer? {
        return pixelBuffer(width: Int(size.width), height: Int(size.height))
    }
    
    /// Resizes the image to specified `width` and `height`, then converts it to an ARGB `CVPixelBuffer`.
    /// - Parameters:
    ///   - width: The target width of the resized image.
    ///   - height: The target height of the resized image.
    /// - Returns: An optional `CVPixelBuffer` in ARGB format.
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        return pixelBuffer(width: width, height: height,
                           pixelFormatType: kCVPixelFormatType_32ARGB,
                           colorSpace: CGColorSpaceCreateDeviceRGB(),
                           alphaInfo: .noneSkipFirst)
    }
    
    /// Converts the image to a grayscale `CVPixelBuffer`.
    /// - Returns: An optional `CVPixelBuffer` in grayscale format.
    public func pixelBufferGray() -> CVPixelBuffer? {
        return pixelBufferGray(width: Int(size.width), height: Int(size.height))
    }
    
    /// Resizes the image to specified `width` and `height`, then converts it to a grayscale `CVPixelBuffer`.
    /// - Parameters:
    ///   - width: The target width of the resized image.
    ///   - height: The target height of the resized image.
    /// - Returns: An optional `CVPixelBuffer` in grayscale format.
    public func pixelBufferGray(width: Int, height: Int) -> CVPixelBuffer? {
        return pixelBuffer(width: width, height: height,
                           pixelFormatType: kCVPixelFormatType_OneComponent8,
                           colorSpace: CGColorSpaceCreateDeviceGray(),
                           alphaInfo: .none)
    }
    
    /// Converts the image to a `CVPixelBuffer` with specified parameters.
    /// - Parameters:
    ///   - width: The target width of the image.
    ///   - height: The target height of the image.
    ///   - pixelFormatType: The pixel format type of the output buffer.
    ///   - colorSpace: The color space to use for conversion.
    ///   - alphaInfo: The alpha channel configuration.
    /// - Returns: An optional `CVPixelBuffer` containing the converted image.
    public func pixelBuffer(width: Int, height: Int,
                            pixelFormatType: OSType,
                            colorSpace: CGColorSpace,
                            alphaInfo: CGImageAlphaInfo) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        
        // Create a pixel buffer with the given attributes
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         pixelFormatType,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }
        
        let flags = CVPixelBufferLockFlags(rawValue: 0)
        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
            return nil
        }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }
        
        // Create a CGContext from the pixel buffer
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: alphaInfo.rawValue)
        else {
            return nil
        }
        
        // Flip the image vertically to match coordinate system
        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        
        return pixelBuffer
    }
}

extension UIImage {
    /// Creates a new UIImage from a `CVPixelBuffer`.
    /// - Parameter pixelBuffer: The pixel buffer containing image data.
    /// - Returns: A new UIImage instance if conversion is successful, otherwise nil.
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        if let cgImage = CGImage.create(pixelBuffer: pixelBuffer) {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }
    
    /*
     // Alternative implementation:
     public convenience init?(pixelBuffer: CVPixelBuffer) {
     // This converts the image to a CIImage first and then to a UIImage.
     // Does not appear to work on the simulator but is OK on the device.
     self.init(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
     }
     */
    
    /// Creates a new UIImage from a `CVPixelBuffer` using a Core Image context.
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer containing image data.
    ///   - context: A `CIContext` used for rendering the image.
    /// - Returns: A new UIImage instance if conversion is successful, otherwise nil.
    public convenience init?(pixelBuffer: CVPixelBuffer, context: CIContext) {
        if let cgImage = CGImage.create(pixelBuffer: pixelBuffer, context: context) {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }
}

#endif
