// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftFin",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftFin",
            targets: ["SwiftFin"])
    ],
    targets: [
        .target(
            name: "SwiftFin",
            path: "SwiftFin"
        ),
        .testTarget(
            name: "SwiftFinTests",
            dependencies: ["SwiftFin"],
            path: "SwiftFinTests"
        )
    ]
)