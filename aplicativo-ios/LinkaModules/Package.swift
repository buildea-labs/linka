// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LinkaModules",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LinkaModules",
            targets: ["LinkaModules"]
        )
    ],
    dependencies: [
        .package(path: "../NetworkCore"),
        .package(path: "../MeasurementHistory"),
        .package(path: "../NetworkAssist"),
        .package(path: "../LinkaEntitlements")
    ],
    targets: [
        .target(
            name: "LinkaModules",
            dependencies: [
                .product(name: "NetworkCore", package: "NetworkCore"),
                .product(name: "MeasurementHistory", package: "MeasurementHistory"),
                .product(name: "NetworkAssist", package: "NetworkAssist"),
                .product(name: "LinkaEntitlements", package: "LinkaEntitlements")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "LinkaModulesTests",
            dependencies: ["LinkaModules"],
            path: "Tests"
        )
    ]
)
