// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MiniinKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MiniinKit", targets: ["MiniinKit"])
    ],
    targets: [
        .target(
            name: "MiniinKit",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MiniinKitTests",
            dependencies: ["MiniinKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
