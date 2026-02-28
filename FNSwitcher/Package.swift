// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FNSwitcher",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "FNSwitcher",
            path: "FNSwitcher",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "FNSwitcherTests",
            dependencies: ["FNSwitcher"],
            path: "FNSwitcherTests"
        ),
    ]
)
