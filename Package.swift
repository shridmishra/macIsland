// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacIsland",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MacIsland",
            targets: ["MacIsland"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacIsland",
            dependencies: [],
            path: "Sources/MacIsland",
            exclude: [
                "Resources/Info.plist"
            ]
        )
    ]
)
