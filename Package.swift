// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapgoCapacitorZip",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapgoCapacitorZip",
            targets: ["CapacitorZipPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19")
    ],
    targets: [
        .target(
            name: "CapacitorZipPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            path: "ios/Sources/CapacitorZipPlugin"),
        .testTarget(
            name: "CapacitorZipPluginTests",
            dependencies: ["CapacitorZipPlugin"],
            path: "ios/Tests/CapacitorZipPluginTests")
    ]
)
