// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "HAClient",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v11),
        .watchOS(.v5),
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "HAClient",
            targets: ["HAClient"]),
    ],
    dependencies: [
        .package(
            name: "Nimble",
            url: "https://github.com/Quick/Nimble.git",
            .upToNextMajor(from: "8.0.1")
        ),
    ],
    targets: [
        .target(
            name: "HAClient",
            dependencies: []
        ),
        .testTarget(
            name: "HAClientTests",
            dependencies: ["HAClient", "Nimble"]
        ),
    ]
)
