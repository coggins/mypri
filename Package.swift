// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyPri",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "MyPriKit", targets: ["MyPriKit"])
    ],
    targets: [
        .target(
            name: "MyPriKit",
            path: "Sources/MyPriKit"
        ),
        .executableTarget(
            name: "MyPri",
            dependencies: ["MyPriKit"],
            path: "Sources/MyPri"
        ),
        .testTarget(
            name: "MyPriKitTests",
            dependencies: ["MyPriKit"],
            path: "Tests/MyPriKitTests"
        )
    ]
)
