import CoreML
import Combine

@available(iOS 13.0, tvOS 13.0, OSX 10.15, *)
extension Publisher where Self.Output: MLFeatureProvider {
  /**
   Operator that lets you run a Core ML model as part of a Combine chain.

   It accepts an MLFeatureProvider object as input, and, if all goes well,
   returns another MLFeatureProvider with the model outputs.

   Since Core ML can give errors, we put everything in a Result object.

   Use the `compactMap` version to always ignore errors, or `tryMap` to
   complete the subscription upon the first error.

   To perform the Core ML request on a background thread, it's probably a good
   idea to write a custom Publisher class, but for simple use cases `map` works
   well enough.
  */
  public func prediction(model: MLModel) -> Publishers.Map<Self, Result<MLFeatureProvider, Error>> {
    map { input in
      do {
        return .success(try model.prediction(from: input))
      } catch {
        return .failure(error)
      }
    }
  }

  public func prediction(model: MLModel) -> Publishers.CompactMap<Self, MLFeatureProvider> {
    compactMap { input in try? model.prediction(from: input) }
  }

  public func prediction(model: MLModel) -> Publishers.TryMap<Self, MLFeatureProvider?> {
    tryMap { input in try model.prediction(from: input) }
  }
}
