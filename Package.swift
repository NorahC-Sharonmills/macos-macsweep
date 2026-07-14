// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacDeepCleaner",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MacDeepCleaner", targets: ["MacDeepCleanerApp"]),
        .library(name: "MacDeepCleanerCore", targets: ["MacDeepCleanerCore"])
    ],
    targets: [
        .target(
            name: "MacDeepCleanerCore",
            path: "Sources/MacDeepCleanerCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "MacDeepCleanerApp",
            dependencies: ["MacDeepCleanerCore"],
            path: "Sources/MacDeepCleanerApp",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MacDeepCleanerTests",
            dependencies: ["MacDeepCleanerCore"],
            path: "Tests/MacDeepCleanerTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
