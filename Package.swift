// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "HAClient",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "HAClient",
            targets: ["HAClient"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble.git", from: "9.2.1")
    ],
    targets: [
        .target(
            name: "HAClient",
            dependencies: []
        ),
        .testTarget(
            name: "HAClientTests",
            dependencies: ["HAClient", "Nimble"]
        )
    ]
)
