// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MBPopup",
    platforms: [
        .macOS("10.14.6"), // Minimum version supported by Xcode 14.3
    ],
    products: [
        .library(
            name: "MBPopup",
            targets: ["MBPopup"]
        ),
    ],
    targets: [
        .target(name: "MBPopup"),
    ]
)
