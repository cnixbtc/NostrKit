// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "NostrKit",
    products: [
        .library(name: "NostrKit", targets: ["NostrKit"]),
        .executable(name: "example", targets: ["Example"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "NostrKit", dependencies: []),
        .testTarget(name: "NostrKitTests", dependencies: ["NostrKit"]),
        .executableTarget(name: "Example", dependencies: ["NostrKit"]),
    ]
)
