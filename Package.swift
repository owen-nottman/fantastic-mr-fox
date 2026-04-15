// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Kit",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Kit",
            path: "Sources",
            exclude: ["Resources/Info.plist"],
            resources: [
                .copy("Resources/Animations"),
                // Drop Nunito .ttf files here for pixel-perfect brand typography
                // .copy("Resources/Fonts"),
            ],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("ScreenCaptureKit"),
            ]
        )
    ]
)
