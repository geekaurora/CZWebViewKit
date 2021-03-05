// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CZWebViewKit",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CZWebViewKit",
            type: .dynamic,
            targets: ["CZWebViewKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/geekaurora/CZUtils.git", from: "3.2.8"),
         .package(url: "https://github.com/geekaurora/SwiftUIRedux.git", from: "1.1.7"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CZWebViewKit",
            dependencies: ["CZUtils", "SwiftUIRedux"]),
    ]
)
