// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SubscriptionStateExample",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "SubscriptionStateExample", targets: ["SubscriptionStateExample"])
    ],
    targets: [
        .target(name: "SubscriptionStateExample"),
        .testTarget(name: "SubscriptionStateExampleTests", dependencies: ["SubscriptionStateExample"])
    ]
)
