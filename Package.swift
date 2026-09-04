// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "InterviewTimer",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "TimerCore", targets: ["TimerCore"]),
    ],
    targets: [
        .target(
            name: "TimerCore",
            path: "Sources/TimerCore"
        ),
        .executableTarget(
            name: "TimerMac",
            dependencies: ["TimerCore"],
            path: "Sources/TimerMac"
        ),
        .testTarget(
            name: "TimerCoreTests",
            dependencies: ["TimerCore"],
            path: "Tests/TimerCoreTests"
        ),
        .testTarget(
            name: "TimerMacTests",
            dependencies: ["TimerMac", "TimerCore"],
            path: "Tests/TimerMacTests"
        ),
    ]
)
