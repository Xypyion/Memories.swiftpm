// swift-tools-version: 5.9

// The Memories app — a tactile digital scrapbook for iPad.
//
// This is a Swift Playgrounds "App Package". It opens and RUNS directly in
// Swift Playgrounds on iPad (no Mac required), and also opens directly in
// Xcode on macOS. See README.md.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Memories",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .iOSApplication(
            name: "Memories",
            targets: ["MemoriesApp"],
            bundleIdentifier: "app.memories.tactile",
            displayVersion: "1.0",
            bundleVersion: "1",
            accentColor: .presetColor(.green),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "MemoriesApp",
            path: "MemoriesApp"
        )
    ]
)
