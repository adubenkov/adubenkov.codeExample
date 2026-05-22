// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AsyncPolicyExample",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "AsyncPolicyExample", targets: ["AsyncPolicyExample"])
    ],
    targets: [
        .target(name: "AsyncPolicyExample"),
        .testTarget(name: "AsyncPolicyExampleTests", dependencies: ["AsyncPolicyExample"])
    ]
)
