#if os(iOS)

import Foundation
import Accelerate

fileprivate func metalCompatiblityAttributes() -> [String: Any] {
  let attributes: [String: Any] = [
    String(kCVPixelBufferMetalCompatibilityKey): true,
    String(kCVPixelBufferOpenGLCompatibilityKey): true,
    String(kCVPixelBufferIOSurfacePropertiesKey): [
      String(kCVPixelBufferIOSurfaceOpenGLESTextureCompatibilityKey): true,
      String(kCVPixelBufferIOSurfaceOpenGLESFBOCompatibilityKey): true,
      String(kCVPixelBufferIOSurfaceCoreAnimationCompatibilityKey): true
    ]
  ]
  return attributes
}

/**
  Creates a pixel buffer of the specified width, height, and pixel format.

  - Note: This pixel buffer is backed by an IOSurface and therefore can be
    turned into a Metal texture.
*/
public func createPixelBuffer(width: Int, height: Int, pixelFormat: OSType) -> CVPixelBuffer? {
  let attributes = metalCompatiblityAttributes() as CFDictionary
  var pixelBuffer: CVPixelBuffer?
  let status = CVPixelBufferCreate(nil, width, height, pixelFormat, attributes, &pixelBuffer)
  if status != kCVReturnSuccess {
    print("Error: could not create pixel buffer", status)
    return nil
  }
  return pixelBuffer
}

/**
  Creates a RGB pixel buffer of the specified width and height.
*/
public func createPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
  createPixelBuffer(width: width, height: height, pixelFormat: kCVPixelFormatType_32BGRA)
}

/**
  Creates a pixel buffer of the specified width, height, and pixel format.

  You probably shouldn't use this one!

  - Note: The new CVPixelBuffer is *not* backed by an IOSurface and therefore
    cannot be turned into a Metal texture.
*/
public func _createPixelBuffer(width: Int, height: Int, pixelFormat: OSType) -> CVPixelBuffer? {
  let bytesPerRow = width * 4
  guard let data = malloc(height * bytesPerRow) else {
    print("Error: out of memory")
    return nil
  }

  let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
    if let ptr = ptr {
      free(UnsafeMutableRawPointer(mutating: ptr))
    }
  }

  var pixelBuffer: CVPixelBuffer?
  let status = CVPixelBufferCreateWithBytes(nil, width, height,
                                            pixelFormat, data,
                                            bytesPerRow, releaseCallback,
                                            nil, nil, &pixelBuffer)
  if status != kCVReturnSuccess {
    print("Error: could not create new pixel buffer")
    free(data)
    return nil
  }

  return pixelBuffer
}

public extension CVPixelBuffer {
  /**
    Copies a CVPixelBuffer to a new CVPixelBuffer that is compatible with Metal.

    - Tip: If CVMetalTextureCacheCreateTextureFromImage is failing, then call
      this method first!
  */
  func copyToMetalCompatible() -> CVPixelBuffer? {
    return deepCopy(withAttributes: metalCompatiblityAttributes())
  }

  /**
    Copies a CVPixelBuffer to a new CVPixelBuffer.

    This lets you specify new attributes, such as whether the new CVPixelBuffer
    must be IOSurface-backed.

    See: https://developer.apple.com/library/archive/qa/qa1781/_index.html
  */
  func deepCopy(withAttributes attributes: [String: Any] = [:]) -> CVPixelBuffer? {
    let srcPixelBuffer = self
    let srcFlags: CVPixelBufferLockFlags = .readOnly
    guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(srcPixelBuffer, srcFlags) else {
      return nil
    }
    defer { CVPixelBufferUnlockBaseAddress(srcPixelBuffer, srcFlags) }

    var combinedAttributes: [String: Any] = [:]

    // Copy attachment attributes.
    if let attachments = CVBufferGetAttachments(srcPixelBuffer, .shouldPropagate) as? [String: Any] {
      for (key, value) in attachments {
        combinedAttributes[key] = value
      }
    }

    // Add user attributes.
    combinedAttributes = combinedAttributes.merging(attributes) { $1 }

    var maybePixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     CVPixelBufferGetWidth(srcPixelBuffer),
                                     CVPixelBufferGetHeight(srcPixelBuffer),
                                     CVPixelBufferGetPixelFormatType(srcPixelBuffer),
                                     combinedAttributes as CFDictionary,
                                     &maybePixelBuffer)

    guard status == kCVReturnSuccess, let dstPixelBuffer = maybePixelBuffer else {
      return nil
    }

    let dstFlags = CVPixelBufferLockFlags(rawValue: 0)
    guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(dstPixelBuffer, dstFlags) else {
      return nil
    }
    defer { CVPixelBufferUnlockBaseAddress(dstPixelBuffer, dstFlags) }

    for plane in 0...max(0, CVPixelBufferGetPlaneCount(srcPixelBuffer) - 1) {
      if let srcAddr = CVPixelBufferGetBaseAddressOfPlane(srcPixelBuffer, plane),
         let dstAddr = CVPixelBufferGetBaseAddressOfPlane(dstPixelBuffer, plane) {
        let srcBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(srcPixelBuffer, plane)
        let dstBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(dstPixelBuffer, plane)

        for h in 0..<CVPixelBufferGetHeightOfPlane(srcPixelBuffer, plane) {
          let srcPtr = srcAddr.advanced(by: h*srcBytesPerRow)
          let dstPtr = dstAddr.advanced(by: h*dstBytesPerRow)
          dstPtr.copyMemory(from: srcPtr, byteCount: srcBytesPerRow)
        }
      }
    }
    return dstPixelBuffer
  }
}

#endif
