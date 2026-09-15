// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WorldOfMysteries",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "WorldOfMysteries", targets: ["WorldOfMysteries"])
    ],
    targets: [
        .target(
            name: "WorldOfMysteriesCore",
            path: "Sources/WorldOfMysteriesCore"
        ),
        .target(
            name: "WorldOfMysteriesFeatures",
            dependencies: ["WorldOfMysteriesCore"],
            path: "Sources/WorldOfMysteriesFeatures"
        ),
        .executableTarget(
            name: "WorldOfMysteries",
            dependencies: ["WorldOfMysteriesCore", "WorldOfMysteriesFeatures"],
            path: "Sources/WorldOfMysteries"
        ),
        .testTarget(
            name: "WorldOfMysteriesCoreTests",
            dependencies: ["WorldOfMysteriesCore"],
            path: "Tests/WorldOfMysteriesCoreTests"
        ),
        .testTarget(
            name: "WorldOfMysteriesFeaturesTests",
            dependencies: ["WorldOfMysteriesFeatures"],
            path: "Tests/WorldOfMysteriesFeaturesTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
