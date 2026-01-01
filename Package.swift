// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RepoBar",
    platforms: [
        // Sonoma is macOS 14.x, so target that as the minimum.
        .macOS(.v14),
        // Keep an iOS deployment target for the shared core, but use a
        // currently supported version so the manifest parses on older tools.
        .iOS(.v17),
    ],
    products: [
        .library(name: "RepoBarCore", targets: ["RepoBarCore"]),
        // Main macOS menu bar app.
        .executable(name: "RepoBar", targets: ["RepoBar"]),
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/Commander", from: "0.2.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.1"),
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess", exact: "1.2.2"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.1"),
        .package(url: "https://github.com/apple/swift-log", from: "1.8.0"),
        .package(url: "https://github.com/openid/AppAuth-iOS", from: "2.0.0"),
        // Use a locally vendored Apollo 2.0.3 package to avoid requiring newer Swift tools.
        .package(name: "apollo-ios", path: "Vendor/apollo-ios"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "8.6.0"),
        .package(url: "https://github.com/apple/swift-markdown", from: "0.7.3"),
    ],
    targets: [
        .target(
            name: "RepoBarCore",
            dependencies: [
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Markdown", package: "swift-markdown"),
            ]),
        .executableTarget(
            name: "RepoBar",
            dependencies: [
                "RepoBarCore",
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "MenuBarExtraAccess", package: "MenuBarExtraAccess"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "AppAuth", package: "AppAuth-iOS"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "Logging", package: "swift-log"),
            ],
            exclude: ["Resources/Info.plist"],
            swiftSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/RepoBar/Resources/Info.plist",
                ]),
            ]),
        .testTarget(
            name: "RepoBarTests",
            dependencies: ["RepoBar", "RepoBarCore"],
            swiftSettings: [
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
