// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "coding_balance_display_mac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "BalanceDisplayKit",
            targets: ["BalanceDisplayKit"]
        ),
        .executable(
            name: "CodingBalanceDisplayMac",
            targets: ["CodingBalanceDisplayMac"]
        )
    ],
    targets: [
        .target(
            name: "BalanceDisplayKit"
        ),
        .executableTarget(
            name: "CodingBalanceDisplayMac",
            dependencies: ["BalanceDisplayKit"]
        ),
        .testTarget(
            name: "BalanceDisplayKitTests",
            dependencies: ["BalanceDisplayKit"]
        )
    ]
)
