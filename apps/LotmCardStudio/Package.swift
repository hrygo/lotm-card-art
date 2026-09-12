// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LotmCardStudio",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LotmCardStudio", targets: ["LotmCardStudio"])
    ],
    targets: [
        .target(
            name: "LotmCardStudioCore",
            path: "Sources/LotmCardStudioCore"
        ),
        .target(
            name: "LotmCardStudioFeatures",
            dependencies: ["LotmCardStudioCore"],
            path: "Sources/LotmCardStudioFeatures"
        ),
        .executableTarget(
            name: "LotmCardStudio",
            dependencies: ["LotmCardStudioCore", "LotmCardStudioFeatures"],
            path: "Sources/LotmCardStudio"
        ),
        .testTarget(
            name: "LotmCardStudioCoreTests",
            dependencies: ["LotmCardStudioCore"],
            path: "Tests/LotmCardStudioCoreTests"
        ),
        .testTarget(
            name: "LotmCardStudioFeaturesTests",
            dependencies: ["LotmCardStudioFeatures"],
            path: "Tests/LotmCardStudioFeaturesTests"
        )
    ]
)
