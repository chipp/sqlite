// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sqlite",
    platforms: [
        .macOS(.v10_12),
    ],
    products: [
        .library(name: "sqlite", targets: ["sqlite"])
    ],
    dependencies: [.package(url: "https://github.com/Quick/Nimble", .upToNextMinor(from: "9.0.0"))],
    targets: [
        .target(name: "sqlite"),
        .testTarget(name: "sqliteTests", dependencies: ["sqlite", "Nimble"])
    ]
)
