// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MiniinKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MiniinCore", targets: ["MiniinCore"]),
        .library(name: "MiniinDesignSystem", targets: ["MiniinDesignSystem"]),
        .library(name: "MiniinEngines", targets: ["MiniinEngines"]),
        .library(name: "MiniinFeatures", targets: ["MiniinFeatures"])
    ],
    targets: [
        .target(
            name: "MiniinCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MiniinDesignSystem",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MiniinEngines",
            dependencies: ["MiniinCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MiniinFeatures",
            dependencies: ["MiniinCore", "MiniinDesignSystem"],
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MiniinKitTests",
            dependencies: ["MiniinCore", "MiniinDesignSystem", "MiniinEngines", "MiniinFeatures"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
