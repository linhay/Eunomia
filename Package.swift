// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnjoyableKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "EnjoyableKit", targets: ["EnjoyableKit"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            exact: "1.23.1"
        )
    ],
    targets: [
        .target(
            name: "EnjoyableKit",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources/EnjoyableKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "EnjoyableKitTests",
            dependencies: [
                "EnjoyableKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Tests/EnjoyableKitTests"
        )
    ]
)
