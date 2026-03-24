// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "ZBSimplePluginManager",
    products: [
        .library(
            name: "ZBSimplePluginManager",
            targets: ["ZBSimplePluginManager"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ZBSimplePluginManager",
            dependencies: []),
        .testTarget(
            name: "ZBSimplePluginManagerTests",
            dependencies: ["ZBSimplePluginManager"]),
    ]
)
