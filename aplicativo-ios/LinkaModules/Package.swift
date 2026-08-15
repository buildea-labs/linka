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
        .package(path: "../MeasurementHistoryCloudKit"),
        .package(path: "../NetworkAssist"),
        .package(path: "../NetworkInsights"),
        .package(path: "../NetworkDiagnostics"),
        .package(path: "../LinkaEntitlements")
    ],
    targets: [
        .target(
            name: "LinkaModules",
            dependencies: [
                .product(name: "NetworkCore", package: "NetworkCore"),
                .product(name: "MeasurementHistory", package: "MeasurementHistory"),
                .product(name: "MeasurementHistoryCloudKit", package: "MeasurementHistoryCloudKit"),
                .product(name: "NetworkAssist", package: "NetworkAssist"),
                .product(name: "NetworkInsights", package: "NetworkInsights"),
                .product(name: "NetworkDiagnostics", package: "NetworkDiagnostics"),
                .product(name: "LinkaEntitlements", package: "LinkaEntitlements")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "LinkaModulesTests",
            dependencies: [
                "LinkaModules",
                .product(name: "MeasurementHistoryCloudKit", package: "MeasurementHistoryCloudKit")
            ],
            path: "Tests"
        )
    ]
)
