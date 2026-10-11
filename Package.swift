// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MBPopup",
    platforms: [
        .macOS(.v14),
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
