import ProjectDescription

let project = Project(
    name: "Enjoyable",
    organizationName: "Enjoyable",
    packages: [
        .local(path: ".")
    ],
    settings: .settings(base: [
        "SWIFT_VERSION": "5.9",
        "MACOSX_DEPLOYMENT_TARGET": "11.0"
    ]),
    targets: [
        Target(
            name: "Enjoyable",
            platform: .macOS,
            product: .app,
            bundleId: "com.linhey.enjoyable",
            infoPlist: .file(path: "Sources/EnjoyableApp/Info.plist"),
            sources: ["Sources/EnjoyableApp/**"],
            resources: [],
            dependencies: [
                .package(product: "EnjoyableKit")
            ],
            settings: .settings(base: [
                "CODE_SIGN_STYLE": "Automatic"
            ])
        ),
    ]
)
