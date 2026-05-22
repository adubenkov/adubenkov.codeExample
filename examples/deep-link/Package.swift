// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DeepLinkExample",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "DeepLinkExample", targets: ["DeepLinkExample"])
    ],
    targets: [
        .target(name: "DeepLinkExample"),
        .testTarget(name: "DeepLinkExampleTests", dependencies: ["DeepLinkExample"])
    ]
)
