import Vision

/// Returns the top `k` predictions from Core ML classification results as an
/// array of `(String, Double)` pairs.
/// - Parameters:
///   - k: The number of top predictions to return.
///   - prob: A dictionary containing class labels as keys and their probabilities as values.
/// - Returns: An array of tuples containing class labels and their respective probabilities, sorted in descending order.
public func top(_ k: Int, _ prob: [String: Double]) -> [(String, Double)] {
    return Array(prob.map { x in (x.key, x.value) }
        .sorted(by: { a, b -> Bool in a.1 > b.1 })
        .prefix(through: min(k, prob.count) - 1))
}

/// Returns the top `k` predictions from Vision classification results as an
/// array of `(String, Double)` pairs.
/// - Parameters:
///   - k: The number of top predictions to return.
///   - observations: An array of `VNClassificationObservation` objects containing classification results.
/// - Returns: An array of tuples containing class labels and their respective confidence scores, sorted in descending order.
public func top(_ k: Int, _ observations: [VNClassificationObservation]) -> [(String, Double)] {
    // The Vision observations are already sorted by confidence.
    return observations.prefix(through: min(k, observations.count) - 1)
        .map { ($0.identifier, Double($0.confidence)) }
}
