// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnjoyableCore",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "EnjoyableCore", type: .dynamic, targets: ["EnjoyableCore"])
    ],
    targets: [
        .target(
            name: "EnjoyableCore",
            path: "Sources/EnjoyableCore"
        )
    ]
)
