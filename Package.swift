// swift-tools-version: 6.2
import PackageDescription

// Dependency-free by design: every layer is built on Apple frameworks
// (Speech, AVFoundation, AppKit, CoreGraphics) shipped with macOS 26.
let package = Package(
  name: "sokki",
  platforms: [.macOS(.v26)],
  products: [
    .executable(name: "Sokki", targets: ["Sokki"])
  ],
  targets: [
    .target(name: "HotkeyKit"),
    .target(name: "AudioCapture"),
    .target(name: "Transcription", dependencies: ["AudioCapture"]),
    .target(name: "TextInsertion"),
    .executableTarget(
      name: "Sokki",
      dependencies: ["HotkeyKit", "AudioCapture", "Transcription", "TextInsertion"]
    ),
    .testTarget(name: "HotkeyKitTests", dependencies: ["HotkeyKit"]),
    .testTarget(name: "AudioCaptureTests", dependencies: ["AudioCapture"]),
    .testTarget(
      name: "TranscriptionTests",
      dependencies: ["Transcription"],
      resources: [.copy("Fixtures")]
    ),
    .testTarget(name: "TextInsertionTests", dependencies: ["TextInsertion"]),
  ]
)
