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
        // Elegant Emoji Picker for beautiful emoji selection
        .package(url: "https://github.com/Finalet/Elegant-Emoji-Picker.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Spawn-App-iOS-SwiftUI",
            dependencies: [
                .product(name: "ElegantEmojiPicker", package: "Elegant-Emoji-Picker")
            ]),
        .testTarget(
            name: "Spawn-App-iOS-SwiftUITests",
            dependencies: ["Spawn-App-iOS-SwiftUI"])
    ]
) 