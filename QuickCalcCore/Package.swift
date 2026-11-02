// swift-tools-version: 6.0
import PackageDescription

// The expression engine, units and currencies, kept apart from the app so they can be tested with `swift test` alone.
let package = Package(
    name: "QuickCalcCore",
    platforms: [.macOS(.v15)],
    products: [.library(name: "QuickCalcCore", targets: ["QuickCalcCore"])],
    targets: [
        .target(name: "QuickCalcCore"),
        .testTarget(name: "QuickCalcCoreTests", dependencies: ["QuickCalcCore"]),
    ]
)
