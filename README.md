# ShipKit

ShipKit is a personal collection of Swift utilities and UI components that I use across my own projects. It's designed to be a centralized toolkit that consolidates common functionality I frequently need in iOS, macOS, tvOS, watchOS, and visionOS applications.

While this package is primarily maintained for my personal use, I've made it open source in case others find it useful for their projects as well.

## Features

- Core utilities and extensions
- Networking components
- UI components and views
- RevenueCat integration utilities
- Localization support

## Requirements

- iOS 17.0+
- macOS 14.0+
- tvOS 17.0+
- watchOS 10.0+
- visionOS 1.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Add ShipKit to your project through Xcode's Swift Package Manager:

1. In Xcode, select "File" → "Add Packages..."
2. Enter the repository URL: `https://github.com/ysmaliak/ShipKit.git`
3. Select the version you want to use

Or add it to your `Package.swift` file: 
```swift
dependencies: [
    .package(url: "https://github.com/ysmaliak/ShipKit.git", from: "1.0.0")
]
```

## Usage

Import the modules you need:
```swift
import ShipKit // For all components
import ShipKitCore // For core utilities
import ShipKitNetworking // For networking components
import ShipKitUI // For UI components
```

## Components

- **ShipKitCore**: Core utilities, extensions, and base functionality
- **ShipKitNetworking**: Networking layer and utilities
- **ShipKitUI**: UI components and views
- **ShipKit**: Main module that includes all components

## Design Philosophy

ShipKit is designed with a focus on reusability across my personal projects. It encapsulates common patterns and solutions I've found useful, making it easier to maintain consistency across different applications. While the package evolves based on my specific needs, I maintain it with clean architecture principles in mind.

## License

ShipKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Author

Yan Smaliak