// swift-tools-version: 5.9
// This Package.swift exists for IDE support and SPM compatibility.
// The CI pipeline uses swiftc -typecheck directly (bypasses SPM linking issues).
import PackageDescription

let package = Package(
    name: "DailyWorkout",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DailyWorkout", targets: ["DailyWorkout"]),
    ],
    targets: [
        .target(
            name: "DailyWorkout",
            path: ".",
            exclude: [
                ".git",
                ".github",
                ".build",
                ".swiftpm",
                ".gitignore",
                "README.md",
                "Package.swift",
                "build.log"
            ]
        ),
    ]
)
