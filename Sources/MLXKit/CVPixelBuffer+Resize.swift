import Foundation
import Accelerate
import CoreImage

/**
  First crops the pixel buffer, then resizes it.

  This function requires the caller to pass in both the source and destination
  pixel buffers. The dimensions of destination pixel buffer should be at least
  `scaleWidth` x `scaleHeight` pixels.
*/
public func resizePixelBuffer(from srcPixelBuffer: CVPixelBuffer,
                              to dstPixelBuffer: CVPixelBuffer,
                              cropX: Int,
                              cropY: Int,
                              cropWidth: Int,
                              cropHeight: Int,
                              scaleWidth: Int,
                              scaleHeight: Int) {

  assert(CVPixelBufferGetWidth(dstPixelBuffer) >= scaleWidth)
  assert(CVPixelBufferGetHeight(dstPixelBuffer) >= scaleHeight)

  let srcFlags = CVPixelBufferLockFlags.readOnly
  let dstFlags = CVPixelBufferLockFlags(rawValue: 0)

  guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(srcPixelBuffer, srcFlags) else {
    print("Error: could not lock source pixel buffer")
    return
  }
  defer { CVPixelBufferUnlockBaseAddress(srcPixelBuffer, srcFlags) }

  guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(dstPixelBuffer, dstFlags) else {
    print("Error: could not lock destination pixel buffer")
    return
  }
  defer { CVPixelBufferUnlockBaseAddress(dstPixelBuffer, dstFlags) }

  guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer),
        let dstData = CVPixelBufferGetBaseAddress(dstPixelBuffer) else {
    print("Error: could not get pixel buffer base address")
    return
  }

  let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
  let offset = cropY*srcBytesPerRow + cropX*4
  var srcBuffer = vImage_Buffer(data: srcData.advanced(by: offset),
                                height: vImagePixelCount(cropHeight),
                                width: vImagePixelCount(cropWidth),
                                rowBytes: srcBytesPerRow)

  let dstBytesPerRow = CVPixelBufferGetBytesPerRow(dstPixelBuffer)
  var dstBuffer = vImage_Buffer(data: dstData,
                                height: vImagePixelCount(scaleHeight),
                                width: vImagePixelCount(scaleWidth),
                                rowBytes: dstBytesPerRow)

  let error = vImageScale_ARGB8888(&srcBuffer, &dstBuffer, nil, vImage_Flags(0))
  if error != kvImageNoError {
    print("Error:", error)
  }
}

/**
  First crops the pixel buffer, then resizes it.

  This allocates a new destination pixel buffer that is Metal-compatible.
*/
public func resizePixelBuffer(_ srcPixelBuffer: CVPixelBuffer,
                              cropX: Int,
                              cropY: Int,
                              cropWidth: Int,
                              cropHeight: Int,
                              scaleWidth: Int,
                              scaleHeight: Int) -> CVPixelBuffer? {

  let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
  let dstPixelBuffer = createPixelBuffer(width: scaleWidth, height: scaleHeight,
                                         pixelFormat: pixelFormat)

  if let dstPixelBuffer = dstPixelBuffer {
    CVBufferPropagateAttachments(srcPixelBuffer, dstPixelBuffer)

    resizePixelBuffer(from: srcPixelBuffer, to: dstPixelBuffer,
                      cropX: cropX, cropY: cropY,
                      cropWidth: cropWidth, cropHeight: cropHeight,
                      scaleWidth: scaleWidth, scaleHeight: scaleHeight)
  }

  return dstPixelBuffer
}

/**
  Resizes a CVPixelBuffer to a new width and height.

  This function requires the caller to pass in both the source and destination
  pixel buffers. The dimensions of destination pixel buffer should be at least
  `width` x `height` pixels.
*/
public func resizePixelBuffer(from srcPixelBuffer: CVPixelBuffer,
                              to dstPixelBuffer: CVPixelBuffer,
                              width: Int, height: Int) {
  resizePixelBuffer(from: srcPixelBuffer, to: dstPixelBuffer,
                    cropX: 0, cropY: 0,
                    cropWidth: CVPixelBufferGetWidth(srcPixelBuffer),
                    cropHeight: CVPixelBufferGetHeight(srcPixelBuffer),
                    scaleWidth: width, scaleHeight: height)
}

/**
  Resizes a CVPixelBuffer to a new width and height.

  This allocates a new destination pixel buffer that is Metal-compatible.
*/
public func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer,
                              width: Int, height: Int) -> CVPixelBuffer? {
  return resizePixelBuffer(pixelBuffer, cropX: 0, cropY: 0,
                           cropWidth: CVPixelBufferGetWidth(pixelBuffer),
                           cropHeight: CVPixelBufferGetHeight(pixelBuffer),
                           scaleWidth: width, scaleHeight: height)
}

/**
  Resizes a CVPixelBuffer to a new width and height, using Core Image.
*/
public func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer,
                              width: Int, height: Int,
                              output: CVPixelBuffer, context: CIContext) {
  let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
  let sx = CGFloat(width) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
  let sy = CGFloat(height) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
  let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
  let scaledImage = ciImage.transformed(by: scaleTransform)
  context.render(scaledImage, to: output)
}
