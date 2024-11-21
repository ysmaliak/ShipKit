// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ShipKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "ShipKit",
            targets: ["ShipKit"]
        ),
        .library(
            name: "ShipKitCore",
            targets: ["ShipKitCore"]
        ),
        .library(
            name: "ShipKitNetworking",
            targets: ["ShipKitNetworking"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ysmaliak/RevenueCatUtilities.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.16.0"),
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.5.0"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", from: "5.3.0"),
        .package(url: "https://github.com/liamnichols/xcstrings-tool-plugin.git", from: "1.0.0"),
        .package(url: "https://github.com/evgenyneu/keychain-swift.git", from: "24.0.0")
    ],
    targets: [
        .target(
            name: "ShipKit",
            dependencies: [
                "ShipKitCore",
                "ShipKitNetworking"
            ]
        ),
        .target(
            name: "ShipKitCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Inject", package: "Inject"),
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols"),
                .product(name: "XCStringsToolPlugin", package: "xcstrings-tool-plugin"),
                .product(name: "KeychainSwift", package: "keychain-swift")
            ],
            resources: [
                .process("Resources/Localizable.xcstrings")
            ]
        ),
        .target(
            name: "ShipKitNetworking",
            dependencies: [
                "ShipKitCore"
            ]
        )
    ]
)
