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
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.10.2"),
        .package(url: "https://github.com/auth0/JWTDecode.swift", exact: "3.3.0")
    ],
    targets: [
        .target(
            name: "ASC",
            dependencies: [
                "Alamofire",
                .product(name: "JWTDecode", package: "JWTDecode.swift"),
            ]
        ),
        .testTarget(
            name: "ASCTests",
            dependencies: ["ASC"]
        ),
    ]
)
