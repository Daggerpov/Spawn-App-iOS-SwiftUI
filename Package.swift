// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Spawn-App-iOS-SwiftUI",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Spawn-App-iOS-SwiftUI",
            targets: ["Spawn-App-iOS-SwiftUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/maplibre/maplibre-gl-native-distribution.git", .upToNextMajor(from: "5.13.0"))
    ],
    targets: [
        .target(
            name: "Spawn-App-iOS-SwiftUI",
            dependencies: [
                .product(name: "MapLibre", package: "maplibre-gl-native-distribution")
            ]),
        .testTarget(
            name: "Spawn-App-iOS-SwiftUITests",
            dependencies: ["Spawn-App-iOS-SwiftUI"])
    ]
) 