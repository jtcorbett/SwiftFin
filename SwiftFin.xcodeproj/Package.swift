// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftFin",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
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
    ],
    exclude: ["SwiftFinDemo"]
)