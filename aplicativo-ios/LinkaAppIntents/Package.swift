// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LinkaAppIntents",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LinkaAppIntents",
            targets: ["LinkaAppIntents"]
        )
    ],
    targets: [
        .target(
            name: "LinkaAppIntents",
            path: "Sources"
        ),
        .testTarget(
            name: "LinkaAppIntentsTests",
            dependencies: ["LinkaAppIntents"],
            path: "Tests"
        )
    ]
)
