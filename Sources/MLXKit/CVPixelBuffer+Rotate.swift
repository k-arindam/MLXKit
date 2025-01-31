import Foundation
import Accelerate

/**
  Rotates a CVPixelBuffer by the provided factor of 90 counterclock-wise.

  This function requires the caller to pass in both the source and destination
  pixel buffers. The width and height of destination pixel buffer should be the
  opposite of the source's dimensions if rotating by 90 or 270 degrees.
*/
public func rotate90PixelBuffer(from srcPixelBuffer: CVPixelBuffer,
                                to dstPixelBuffer: CVPixelBuffer,
                                factor: UInt8) {
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

  let srcWidth = CVPixelBufferGetWidth(srcPixelBuffer)
  let srcHeight = CVPixelBufferGetHeight(srcPixelBuffer)

  let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
  var srcBuffer = vImage_Buffer(data: srcData,
                                height: vImagePixelCount(srcHeight),
                                width: vImagePixelCount(srcWidth),
                                rowBytes: srcBytesPerRow)

  let dstWidth = CVPixelBufferGetWidth(dstPixelBuffer)
  let dstHeight = CVPixelBufferGetHeight(dstPixelBuffer)
  let dstBytesPerRow = CVPixelBufferGetBytesPerRow(dstPixelBuffer)
  var dstBuffer = vImage_Buffer(data: dstData,
                                height: vImagePixelCount(dstHeight),
                                width: vImagePixelCount(dstWidth),
                                rowBytes: dstBytesPerRow)

  var color = UInt8(0)
  let error = vImageRotate90_ARGB8888(&srcBuffer, &dstBuffer, factor, &color, vImage_Flags(0))
  if error != kvImageNoError {
    print("Error:", error)
  }
}

/**
  Rotates a CVPixelBuffer by the provided factor of 90 counterclock-wise.

  This allocates a new destination pixel buffer that is Metal-compatible.
*/
public func rotate90PixelBuffer(_ srcPixelBuffer: CVPixelBuffer, factor: UInt8) -> CVPixelBuffer? {
  var dstWidth = CVPixelBufferGetWidth(srcPixelBuffer)
  var dstHeight = CVPixelBufferGetHeight(srcPixelBuffer)
  if factor % 2 == 1 {
    swap(&dstWidth, &dstHeight)
  }

  let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
  let dstPixelBuffer = createPixelBuffer(width: dstWidth, height: dstHeight, pixelFormat: pixelFormat)

  if let dstPixelBuffer = dstPixelBuffer {
    CVBufferPropagateAttachments(srcPixelBuffer, dstPixelBuffer)
    rotate90PixelBuffer(from: srcPixelBuffer, to: dstPixelBuffer, factor: factor)
  }
  return dstPixelBuffer
}
