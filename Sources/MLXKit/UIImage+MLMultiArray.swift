import Foundation
import CoreML

#if canImport(UIKit)
import UIKit

public extension UIImage {
    // Define a typealias for the shape of the MLMultiArray
    typealias Shape = [NSNumber]
    
    /// Converts a UIImage to an MLMultiArray representation.
    /// - Parameters:
    ///   - batch: The batch size, typically 1 for a single image.
    ///   - inChannels: The number of input channels (e.g., 4 for RGBA, default 4).
    ///   - outChannels: The number of output channels (e.g., 3 for RGB, default 3).
    ///   - dataType: The data type for the MLMultiArray (default: .float32).
    /// - Returns: An optional MLMultiArray representing the image.
    func toMLMultiArray(batch: NSNumber = 1, inChannels bytesPerPixel: Int = 4, outChannels: Int = 3, dataType: MLMultiArrayDataType = .float32) -> MLMultiArray? {
        let image = self
        guard let pixelBuffer = image.pixelBuffer() else { return nil }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Define the shape of the MLMultiArray: (batch, channels, height, width)
        let shape: Shape = [batch, NSNumber(value: outChannels), NSNumber(value: height), NSNumber(value: width)]
        
        // Try creating the MLMultiArray
        guard let inputFeature = try? MLMultiArray(shape: shape, dataType: dataType) else {
            print("Error: Unable to create MLMultiArray")
            return nil
        }
        
        // Lock the base address of the pixel buffer for safe access
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            print("Error: Unable to get base address of pixel buffer")
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        // Iterate over each pixel and extract RGB(A) values
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let pixel = baseAddress.load(fromByteOffset: offset, as: UInt32.self)
                
                // Extract color components from the pixel value
                let blue = Float((pixel >> 24) & 0xFF) / 255.0
                let green = Float((pixel >> 16) & 0xFF) / 255.0
                let red = Float((pixel >> 8) & 0xFF) / 255.0
                let alpha = Float(pixel & 0xFF) / 255.0
                
                let imgData: [Float] = [red, green, blue, alpha]
                
                if outChannels > imgData.count {
                    print("Error: Unable to create MLMultiArray")
                    return nil
                }
                
                for index in 0..<outChannels {
                    inputFeature[[0, NSNumber(value: index), NSNumber(value: y), NSNumber(value: x)]] = NSNumber(value: imgData[index])
                }
            }
        }
        
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return inputFeature
    }
    
    /// Creates a UIImage from an MLMultiArray.
    /// - Parameters:
    ///   - mlmultiArray: The source MLMultiArray containing image data.
    ///   - height: The image height.
    ///   - width: The image width.
    ///   - dataType: The expected data type (default: Float32).
    ///   - normalize: Whether to normalize pixel values.
    ///   - clip: Whether to clip pixel values to the valid range.
    ///   - scale: Image scale factor.
    ///   - orientation: Image orientation.
    convenience init?<T: BinaryFloatingPoint>(_ mlmultiArray: MLMultiArray, height: Int, width: Int, dataType: T.Type = Float32.self, normalize: Bool = false, clip: Bool = false, scale: CGFloat, orientation: Orientation) {
        let totalPixels = height * width
        
        // Allocate memory for raw pixel data
        guard let rawPointer = malloc(totalPixels * 3) else {
            print("Unable to allocate memory")
            return nil
        }
        
        let bytes = rawPointer.bindMemory(to: UInt8.self, capacity: totalPixels * 3)
        let mlArray = mlmultiArray.dataPointer.bindMemory(to: dataType, capacity: totalPixels * 3)
        
        if normalize {
            var minPixelValue: T = .greatestFiniteMagnitude
            var maxPixelValue: T = -.greatestFiniteMagnitude
            
            // Find min and max pixel values
            for index in 0..<totalPixels {
                let redIndex = index
                let greenIndex = index + totalPixels
                let blueIndex = index + totalPixels * 2

                minPixelValue = min(minPixelValue, mlArray[redIndex], mlArray[greenIndex], mlArray[blueIndex])
                maxPixelValue = max(maxPixelValue, mlArray[redIndex], mlArray[greenIndex], mlArray[blueIndex])
            }
            
            // Normalize pixel values
            for index in 0..<totalPixels {
                let redIndex = index
                let greenIndex = index + totalPixels
                let blueIndex = index + totalPixels * 2

                mlArray[redIndex] = (mlArray[redIndex] - minPixelValue) / (maxPixelValue - minPixelValue)
                mlArray[greenIndex] = (mlArray[greenIndex] - minPixelValue) / (maxPixelValue - minPixelValue)
                mlArray[blueIndex] = (mlArray[blueIndex] - minPixelValue) / (maxPixelValue - minPixelValue)
            }
        }
        
        // Convert normalized pixel values to UInt8
        for index in 0..<mlmultiArray.count / 3 {
            bytes[index * 3 + 0] = UInt8(max(min(mlArray[index] * 255, 255), 0))
            bytes[index * 3 + 1] = UInt8(max(min(mlArray[index + totalPixels] * 255, 255), 0))
            bytes[index * 3 + 2] = UInt8(max(min(mlArray[index + totalPixels * 2] * 255, 255), 0))
        }
        
        let providerSize = totalPixels * 3
        
        // Create CGDataProvider for image data
        guard let provider = CGDataProvider(dataInfo: nil, data: rawPointer, size: providerSize, releaseData: { (_, data, _) in data.deallocate() }) else {
            print("Unable to create CGDataProvider")
            return nil
        }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rowBytes = width * 3
        
        // Create CGImage from pixel data
        guard let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            print("Unable to create CGImage")
            return nil
        }
        
        // Initialize UIImage from CGImage
        self.init(cgImage: cgImage, scale: scale, orientation: orientation)
    }
}
#endif
