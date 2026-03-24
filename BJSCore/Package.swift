// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BJSCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "BJSCore", targets: ["BJSCore"]),
    ],
    targets: [
        .target(name: "BJSCore"),
        .testTarget(name: "BJSCoreTests", dependencies: ["BJSCore"]),
    ]
)
