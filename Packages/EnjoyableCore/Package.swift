// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnjoyableCore",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "EnjoyableCore", type: .dynamic, targets: ["EnjoyableCore"]),
        .executable(name: "Enjoyable", targets: ["EnjoyableApp"])
    ],
    targets: [
        .target(
            name: "EnjoyableCore",
            path: "Sources/EnjoyableCore"
        ),
        .executableTarget(
            name: "EnjoyableApp",
            dependencies: ["EnjoyableCore"],
            path: "Sources/EnjoyableApp"
        ),
        .testTarget(
            name: "EnjoyableCoreTests",
            dependencies: ["EnjoyableCore"],
            path: "Tests/EnjoyableCoreTests"
        )
    ]
)
