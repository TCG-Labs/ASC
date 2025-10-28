// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ASC",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "ASC",
            targets: ["ASC"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", from: "0.61.0"),
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.10.2"),
    ],
    targets: [
        .target(
            name: "ASC",
            dependencies: [
                "Alamofire",
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint"),
            ]
        ),
        .testTarget(
            name: "ASCTests",
            dependencies: ["ASC"]
        ),
    ]
)
