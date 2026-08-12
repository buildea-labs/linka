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
        .package(path: "../MeasurementHistory")
    ],
    targets: [
        .target(
            name: "LinkaModules",
            dependencies: [
                .product(name: "NetworkCore", package: "NetworkCore"),
                .product(name: "MeasurementHistory", package: "MeasurementHistory")
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
