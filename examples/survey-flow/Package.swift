// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SurveyFlowExample",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "SurveyFlowExample", targets: ["SurveyFlowExample"])
    ],
    targets: [
        .target(name: "SurveyFlowExample"),
        .testTarget(name: "SurveyFlowExampleTests", dependencies: ["SurveyFlowExample"])
    ]
)
