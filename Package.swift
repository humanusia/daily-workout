// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DailyWorkout",
    platforms: [.iOS(.v17)],
    products: [
        .executable(name: "DailyWorkout", targets: ["DailyWorkout"]),
    ],
    targets: [
        .executableTarget(
            name: "DailyWorkout",
            path: "."
        ),
    ]
)
