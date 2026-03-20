// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnjoyableKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "EnjoyableKit", type: .dynamic, targets: ["EnjoyableKit"])
    ],
    targets: [
        .target(
            name: "EnjoyableKit",
            path: "Sources/EnjoyableKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "EnjoyableKitTests",
            dependencies: ["EnjoyableKit"],
            path: "Tests/EnjoyableKitTests"
        )
    ]
)
