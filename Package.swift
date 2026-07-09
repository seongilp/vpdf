// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "vpdf",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "vpdf",
            path: "Sources/vpdf",
            swiftSettings: [
                .unsafeFlags(["-O"], .when(configuration: .release))
            ]
        )
    ]
)
