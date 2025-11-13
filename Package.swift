// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Toon",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "Toon",
            targets: ["Toon"]
        ),
    ],
    targets: [
        .target(
            name: "Toon"
        ),
        .testTarget(
            name: "ToonTests",
            dependencies: ["Toon"]
        ),
    ]
)
