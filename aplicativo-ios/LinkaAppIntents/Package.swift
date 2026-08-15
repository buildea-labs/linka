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
    dependencies: [
        .package(path: "../LinkaEntitlements")
    ],
    targets: [
        .target(
            name: "LinkaAppIntents",
            dependencies: [
                .product(name: "LinkaEntitlements", package: "LinkaEntitlements")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "LinkaAppIntentsTests",
            dependencies: ["LinkaAppIntents"],
            path: "Tests"
        )
    ]
)
