#if canImport(UIKit)

import UIKit

extension UIImage {
    
    /// Returns the height of the image in points.
    /// - Returns: Height of the image in points.
    public var heightInPoints: CGFloat { self.size.height }
    
    /// Returns the width of the image in points.
    /// - Returns: Width of the image in points.
    public var widthInPoints: CGFloat { self.size.width }
    
    /// Returns the height of the image in pixels.
    /// - Returns: Height of the image in pixels, considering the image scale.
    public var heightInPixels: CGFloat { heightInPoints * self.scale }
    
    /// Returns the width of the image in pixels.
    /// - Returns: Width of the image in pixels, considering the image scale.
    public var widthInPixels: CGFloat { widthInPoints * self.scale }
    
    /// Fixes the orientation of the image to be portrait up.
    /// - Returns: A new image with the fixed orientation, or nil if the operation fails.
    public var orientationFixed: UIImage? {
        // Check if the image orientation is already in portrait up
        guard imageOrientation != UIImage.Orientation.up else {
            // This is the default orientation, no need to do anything
            return self.copy() as? UIImage
        }
        
        guard let cgImage = self.cgImage else {
            // If the CGImage is not available, return nil
            return nil
        }
        
        guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            // If CGContext can't be created, return nil
            return nil
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        // Apply transformation based on image orientation
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        // Flip image if needed to prevent mirrored image
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            break
        }
        
        // Apply the transformation to the CGContext
        ctx.concatenate(transform)
        
        // Draw the image based on the adjusted orientation
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        guard let newCGImage = ctx.makeImage() else { return nil }
        return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
    }
    
    /// Splits the image into smaller chunks.
    /// - Parameter chunkSize: The size of each chunk in points (default is 100 points).
    /// - Returns: A 2D array of UIImage chunks.
    public func split(chunkSize: CGFloat = 100) -> [[UIImage]] {
        let imageSize = self.size
        let columns = Int(ceil(imageSize.width / chunkSize))
        let rows = Int(ceil(imageSize.height / chunkSize))
        
        var chunks: [[UIImage]] = []
        
        for y in 0..<rows {
            var rowChunks: [UIImage] = []
            for x in 0..<columns {
                // Define the CGRect to extract each chunk
                let chunkRect = CGRect(
                    x: CGFloat(x) * chunkSize,
                    y: CGFloat(y) * chunkSize,
                    width: min(chunkSize, imageSize.width - CGFloat(x) * chunkSize),
                    height: min(chunkSize, imageSize.height - CGFloat(y) * chunkSize)
                )
                
                if let cgImage = self.cgImage?.cropping(to: chunkRect) {
                    let chunkImage = UIImage(cgImage: cgImage)
                    rowChunks.append(chunkImage)
                }
            }
            chunks.append(rowChunks)
        }
        
        return chunks
    }
    
    /// Creates a UIImage from a 2D array of UIImage chunks.
    /// - Parameter chunks: A 2D array of UIImage chunks.
    /// - Returns: A combined UIImage, or nil if the operation fails.
    public convenience init?(chunks: [[UIImage]]) {
        guard !chunks.isEmpty, !chunks[0].isEmpty else { return nil }
        
        let chunkSize = chunks[0][0].size
        let totalWidth = CGFloat(chunks[0].count) * chunkSize.width
        let totalHeight = CGFloat(chunks.count) * chunkSize.height
        
        UIGraphicsBeginImageContext(CGSize(width: totalWidth, height: totalHeight))
        
        for (y, row) in chunks.enumerated() {
            for (x, chunk) in row.enumerated() {
                chunk.draw(in: CGRect(
                    x: CGFloat(x) * chunkSize.width,
                    y: CGFloat(y) * chunkSize.height,
                    width: chunkSize.width,
                    height: chunkSize.height
                ))
            }
        }
        
        guard let combinedImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        UIGraphicsEndImageContext()
        self.init(cgImage: combinedImage)
    }
    
    /// Crops the image to a specified size.
    /// - Parameter size: The size to crop the image to.
    /// - Returns: A new cropped image, or nil if the operation fails.
    public func cropped(to size: CGSize) -> UIImage? {
        // Define the rectangle to crop from the top-left corner (0, 0)
        let cropRect = CGRect(origin: .zero, size: size)
        
        // Ensure that the crop rectangle is within the bounds of the input image
        guard let cgImage = self.cgImage?.cropping(to: cropRect) else {
            return nil // Return nil if cropping fails
        }
        
        // Create and return the cropped UIImage
        return UIImage(cgImage: cgImage)
    }
    
    /// Returns the possible dimensions for resizing the image, ensuring the dimensions do not exceed the specified maximum.
    /// - Parameter maxDims: The maximum dimension for either width or height.
    /// - Returns: A CGSize representing the possible resized dimensions.
    public func possibleDims(maxDims: CGFloat) -> CGSize {
        let image = self
        
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        // Check if the image is already within the size limit
        if originalWidth <= maxDims && originalHeight <= maxDims {
            return image.size
        }
        
        let aspectRatio = originalWidth / originalHeight
        
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if originalWidth > originalHeight {
            newWidth = maxDims
            newHeight = maxDims / aspectRatio
        } else {
            newHeight = maxDims
            newWidth = maxDims * aspectRatio
        }
        
        return CGSize(width: newWidth, height: newHeight)
    }
    
    /// Resizes the image to fit within the maximum dimensions, maintaining the aspect ratio.
    /// - Parameter maxDims: The maximum dimension for either width or height.
    /// - Returns: A resized UIImage.
    public func resized(maxDims: CGFloat) -> UIImage {
        let possibleDims = possibleDims(maxDims: maxDims)
        
        return resized(to: .init(width: possibleDims.width, height: possibleDims.height))
    }
    
    /// Resizes the image to a specific size.
    /// - Parameter newSize: The target size to resize the image to.
    /// - Parameter scale: The scale factor for the image (default is 1).
    /// - Returns: A resized UIImage.
    @nonobjc public func resized(to newSize: CGSize, scale: CGFloat = 1) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let image = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image
    }
    
    /// Rotates the image by a specified number of degrees.
    /// - Parameter degrees: The rotation angle in degrees.
    /// - Parameter keepSize: If true, the new image has the size of the original image. If false, the new image expands to fit all pixels.
    /// - Returns: A rotated UIImage.
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
