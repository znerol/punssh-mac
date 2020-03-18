// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "punssh-mac",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .executable(
            name: "punssh-defaults",
            targets: ["punssh-defaults"]
        ),
        .executable(
            name: "punssh-status",
            targets: ["punssh-status"]
        ),
        .library(
            name: "punssh",
            targets: ["punssh"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "punssh-defaults",
            dependencies: ["Logging", "punssh"]
        ),
        .target(
            name: "punssh-status",
            dependencies: ["Logging", "punssh"]
        ),
        .target(
            name: "punssh",
            dependencies: ["Logging"]
        ),
    ]
)
