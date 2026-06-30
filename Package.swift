// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Meridian",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MeridianCore", targets: ["MeridianCore"]),
        .executable(name: "Meridian", targets: ["Meridian"]),
        .executable(name: "MeridianChecks", targets: ["MeridianChecks"])
    ],
    targets: [
        .target(name: "MeridianCore"),
        .executableTarget(
            name: "Meridian",
            dependencies: ["MeridianCore"]
        ),
        .executableTarget(
            name: "MeridianChecks",
            dependencies: ["MeridianCore"]
        )
    ]
)
