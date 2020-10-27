// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwimplyCache",
    platforms: [
        .iOS(.v10), .watchOS(.v3), .macOS(.v10_12), .tvOS(.v10),
    ],
    products: [
        .library(
            name: "SwimplyCache",
            targets: ["SwimplyCache"]
        ),
    ],
    targets: [
        .target(
            name: "SwimplyCache",
            dependencies: []
        ),
        .testTarget(
            name: "SwimplyCacheTests",
            dependencies: ["SwimplyCache"]
        ),
    ]
)
