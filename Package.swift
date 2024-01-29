// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "NostrKit",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "NostrKit", targets: ["NostrKit"]),
        .executable(name: "example-reader", targets: ["ExampleReader"]),
        .executable(name: "example-writer", targets: ["ExampleWriter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift", exact: .init(stringLiteral: "0.8.1")),
        .package(url: "https://github.com/apple/swift-crypto.git", exact: .init(stringLiteral: "2.1.0")),
    ],
    targets: [
        .target(name: "NostrKit", dependencies: [
            .product(name: "secp256k1", package: "secp256k1.swift"),
            .product(name: "Crypto", package: "swift-crypto"),
        ]),
        .testTarget(name: "NostrKitTests", dependencies: [
            .target(name: "NostrKit"),
        ]),
        .executableTarget(name: "ExampleReader", dependencies: [
            .target(name: "NostrKit"),
        ]),
        .executableTarget(name: "ExampleWriter", dependencies: [
            .target(name: "NostrKit"),
        ]),
    ]
)
