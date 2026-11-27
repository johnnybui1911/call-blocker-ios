// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BlockerCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
    ],
    products: [
        .library(name: "BlockerCore", targets: ["BlockerCore"]),
    ],
    targets: [
        .target(name: "BlockerCore"),
        .testTarget(
            name: "BlockerCoreTests",
            dependencies: ["BlockerCore"]
        ),
    ]
)
