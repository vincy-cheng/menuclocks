// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "MenuClocks",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "MenuClocks", targets: ["MenuClocks"])],
    targets: [
        .target(name: "ClockCore"),
        .executableTarget(name: "MenuClocks", dependencies: ["ClockCore"]),
        .testTarget(name: "ClockCoreTests", dependencies: ["ClockCore"])
    ]
)
