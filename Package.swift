// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RepoBar",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.1"),
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess", exact: "1.2.2"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.1"),
        .package(url: "https://github.com/openid/AppAuth-iOS", from: "2.0.0"),
        .package(url: "https://github.com/apollographql/apollo-ios", from: "2.0.3"),
    ],
    targets: [
        .target(
            name: "RepoBarCore",
            dependencies: [
                .product(name: "Apollo", package: "apollo-ios"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "RepoBar",
            dependencies: [
                "RepoBarCore",
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "MenuBarExtraAccess", package: "MenuBarExtraAccess"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "AppAuth", package: "AppAuth-iOS"),
            ],
            exclude: ["Resources/Info.plist"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/RepoBar/Resources/Info.plist",
                ]),
                ]),
        .executableTarget(
            name: "repobarcli",
            dependencies: [
                "RepoBarCore",
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "RepoBarTests",
            dependencies: ["RepoBar", "RepoBarCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
