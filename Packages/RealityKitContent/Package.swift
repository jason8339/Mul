// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "RealityKitContent",
    platforms: [
        .visionOS(.v26),
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26)
    ],
    products: [
        .library(
            name: "RealityKitContent",
            targets: ["RealityKitContent"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "RealityKitContent",
            dependencies: [],
            resources: [
                // 這行很重要：把 RealityKit 的資產目錄打包進 Bundle.module
                .process("RealityKitContent.rkassets")
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
    ]
)
