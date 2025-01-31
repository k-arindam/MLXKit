import CoreML

extension MLModel {
  /**
    Returns the MLImageConstraint for the given model input, or nil if that
    input doesn't exist or is not an image.
   */
  public func imageConstraint(forInput inputName: String) -> MLImageConstraint? {
    modelDescription.inputDescriptionsByName[inputName]?.imageConstraint
  }
}

#if canImport(UIKit)
import UIKit

@available(iOS 13.0, tvOS 13.0, *)
extension MLModel {
  /**
    Converts a UIImage into an MLFeatureValue, using the image constraint of
    the specified model input.
   */
  public func featureValue(fromUIImage image: UIImage,
                           forInput inputName: String,
                           orientation: CGImagePropertyOrientation = .up,
                           options: [MLFeatureValue.ImageOption: Any]? = nil)
                           -> MLFeatureValue? {

    guard let cgImage = image.cgImage else {
      print("Error: could not convert UIImage to CGImage")
      return nil
    }

    return featureValue(fromCGImage: cgImage, forInput: inputName,
                        orientation: orientation, options: options)
  }
}

#endif

@available(iOS 13.0, tvOS 13.0, OSX 10.15, *)
extension MLModel {
  /**
    Converts a CGImage into an MLFeatureValue, using the image constraint of
    the specified model input.
   */
  public func featureValue(fromCGImage image: CGImage,
                           forInput inputName: String,
                           orientation: CGImagePropertyOrientation = .up,
                           options: [MLFeatureValue.ImageOption: Any]? = nil)
                           -> MLFeatureValue? {

    guard let constraint = imageConstraint(forInput: inputName) else {
      print("Error: could not get image constraint for input named '\(inputName)'")
      return nil
    }

    guard let featureValue = try? MLFeatureValue(cgImage: image,
                                                 orientation: orientation,
                                                 constraint: constraint,
                                                 options: options) else {
      print("Error: could not get feature value for image \(image)")
      return nil
    }

    return featureValue
  }

  /**
    Converts an image file from a URL into an MLFeatureValue, using the image
    constraint of the specified model input.
   */
  public func featureValue(fromImageAt url: URL,
                           forInput inputName: String,
                           orientation: CGImagePropertyOrientation = .up,
                           options: [MLFeatureValue.ImageOption: Any]? = nil) -> MLFeatureValue? {

    guard let constraint = imageConstraint(forInput: inputName) else {
      print("Error: could not get image constraint for input named '\(inputName)'")
      return nil
    }

    guard let featureValue = try? MLFeatureValue(imageAt: url,
                                                 orientation: orientation,
                                                 constraint: constraint,
                                                 options: options) else {
      print("Error: could not get feature value for image at '\(url)'")
      return nil
    }

    return featureValue
  }
}
