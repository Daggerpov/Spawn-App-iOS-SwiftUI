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
        // No external dependencies needed - using standard MapKit
    ],
    targets: [
        .target(
            name: "Spawn-App-iOS-SwiftUI",
            dependencies: []),
        .testTarget(
            name: "Spawn-App-iOS-SwiftUITests",
            dependencies: ["Spawn-App-iOS-SwiftUI"])
    ]
) 