// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FoxBuddy",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "FoxBuddy",
            path: "Sources",
            // Info.plist is excluded from SPM resources — Xcode picks it up automatically
            // when you open Package.swift and set it under target Build Settings → Info.plist File.
            exclude: ["Resources/Info.plist"],
            resources: [
                // Fox animation clips — drop fox-idle.mov, fox-thinking.mov, fox-speaking.mov here
                .copy("Resources/Animations"),
            ],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("ScreenCaptureKit"),
            ]
        )
    ]
)
