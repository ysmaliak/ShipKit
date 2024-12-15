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
        ),
        .library(
            name: "ShipKitUI",
            targets: ["ShipKitUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ysmaliak/RevenueCatUtilities.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.17.0"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", from: "5.3.0"),
        .package(url: "https://github.com/liamnichols/xcstrings-tool-plugin.git", from: "1.0.0"),
        .package(url: "https://github.com/ysmaliak/NetworkKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ShipKit",
            dependencies: [
                "ShipKitCore",
                "ShipKitNetworking",
                "ShipKitUI"
            ]
        ),
        .target(
            name: "ShipKitCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "RevenueCatUtilities", package: "RevenueCatUtilities")
            ],
            resources: [
                .process("Resources/Localizable.xcstrings")
            ],
            plugins: [
                .plugin(name: "XCStringsToolPlugin", package: "xcstrings-tool-plugin")
            ]
        ),
        .target(
            name: "ShipKitNetworking",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "NetworkKit", package: "NetworkKit")
            ]
        ),
        .target(
            name: "ShipKitUI",
            dependencies: [
                "ShipKitCore",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols")
            ],
            resources: [
                .process("Resources/Localizable.xcstrings")
            ],
            plugins: [
                .plugin(name: "XCStringsToolPlugin", package: "xcstrings-tool-plugin")
            ]
        )
    ]
)
