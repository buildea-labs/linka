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
    targets: [
        .target(
            name: "LinkaModules",
            path: "Sources"
        ),
        .testTarget(
            name: "LinkaModulesTests",
            dependencies: ["LinkaModules"],
            path: "Tests"
        )
    ]
)
