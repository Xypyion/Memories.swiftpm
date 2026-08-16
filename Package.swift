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
            path: "MemoriesApp",
            // The demo board's four photographs. An asset catalogue, which is
            // the resource form Swift Playgrounds' own app template uses, so it
            // goes through the pipeline that already builds this app's icon and
            // accent colour rather than around it.
            resources: [.process("Assets.xcassets")]
        )
    ]
)
