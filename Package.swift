// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MeditationLogin",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MeditationLogin", targets: ["MeditationLogin"]),
        .executable(name: "LoginDemo", targets: ["LoginDemo"]),
    ],
    targets: [
        .target(name: "MeditationLogin"),
        .executableTarget(name: "LoginDemo", dependencies: ["MeditationLogin"]),
    ]
)
