// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExpenseTracker",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ExpenseTracker",
            targets: ["ExpenseTracker"]),
    ],
    dependencies: [
        // 可以在这里添加依赖包
    ],
    targets: [
        .target(
            name: "ExpenseTracker",
            dependencies: [],
            path: "iOS-Expense-Tracker",
            exclude: ["ExpenseTracker.xcodeproj"],
            sources: ["."],
            resources: [
                .process("LaunchScreen.storyboard"),
                .process("Info.plist")
            ]
        ),
        .testTarget(
            name: "ExpenseTrackerTests",
            dependencies: ["ExpenseTracker"]),
    ]
)