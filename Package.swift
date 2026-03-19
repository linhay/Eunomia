// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnjoyableKit",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "EnjoyableKit", type: .dynamic, targets: ["EnjoyableKit"]),
        .executable(name: "Enjoyable", targets: ["EnjoyableApp"])
    ],
    targets: [
        .target(
            name: "EnjoyableKit",
            path: "Sources/EnjoyableKit"
        ),
        .executableTarget(
            name: "EnjoyableApp",
            dependencies: ["EnjoyableKit"],
            path: "Sources/EnjoyableApp"
        ),
        .testTarget(
            name: "EnjoyableKitTests",
            dependencies: ["EnjoyableKit"],
            path: "Tests/EnjoyableKitTests"
        )
    ]
)
