// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnjoyableCore",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "EnjoyableCore", type: .dynamic, targets: ["EnjoyableCore"])
    ],
    targets: [
        .target(
            name: "EnjoyableCore",
            path: "Sources/EnjoyableCore"
        ),
        .testTarget(
            name: "EnjoyableCoreTests",
            dependencies: ["EnjoyableCore"],
            path: "Tests/EnjoyableCoreTests"
        )
    ]
)
