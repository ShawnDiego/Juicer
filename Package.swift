// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Juicer",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Juicer",
            targets: ["Juicer"]
        )
    ],
    targets: [
        .target(
            name: "Juicer",
            path: "Sources/Juicer"
        ),
        .testTarget(
            name: "JuicerTests",
            dependencies: ["Juicer"],
            path: "Tests/JuicerTests"
        )
    ]
)
