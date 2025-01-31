# MLXKit

MLXKit is a Swift package that provides utilities and extensions for working with CoreML, images, and multi-dimensional arrays. It simplifies the process of integrating machine learning models into your iOS applications.

## Features

- Extensions for handling `CGImage`, `UIImage`, and `CVPixelBuffer`.
- Utilities for working with `MLMultiArray`.
- Combine support for CoreML models.

## Installation

To install MLXKit, add the following dependency to your `Package.swift` file:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YourProject",
    dependencies: [
        .package(url: "https://github.com/k-arindam/MLXKit.git", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "YourProject",
            dependencies: ["MLXKit"]),
    ]
)
```

## Usage

Working with `UIImage` and `CVPixelBuffer`

```swift
import MLXKit
import UIKit

if let image = UIImage(named: "example") {
    let pixelBuffer = image.toCVPixelBuffer()
    // Use the pixel buffer with your CoreML model
}
```

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

## Contribution

Contributions are welcome! Please open an issue or submit a pull request.