// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenshotMenu",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ScreenshotMenu",
            path: "Sources/ScreenshotMenu"
        )
    ]
)
