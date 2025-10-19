// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Star-system-procedural-",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    products: [
        .library(name: "StarSystemCore", targets: ["StarSystemCore"]),
        .executable(name: "Star-system-procedural-", targets: ["StarSystemCLI"]),
        .executable(name: "StarSystemProceduralUI", targets: ["StarSystemUI"])
    ],
    targets: [
        .target(
            name: "StarSystemCore",
            path: "Sources/StarSystemCore"
        ),
        .executableTarget(
            name: "StarSystemCLI",
            dependencies: ["StarSystemCore"],
            path: "Sources/Star-system-procedural-"
        ),
        .executableTarget(
            name: "StarSystemUI",
            dependencies: ["StarSystemCore"],
            path: "Sources/StarSystemProceduralUI"
        )
    ]
)
