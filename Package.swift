// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EunomiaKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "EunomiaKit", targets: ["EunomiaKit"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            exact: "1.23.1"
        )
    ],
    targets: [
        .target(
            name: "EunomiaKit",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/EunomiaKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "EunomiaKitTests",
            dependencies: [
                "EunomiaKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Tests/EunomiaKitTests"
        )
    ]
)
