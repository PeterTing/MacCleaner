// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacCleaner",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacCleaner", targets: ["MacCleaner"])
    ],
    targets: [
        .executableTarget(
            name: "MacCleaner",
            path: "Sources/MacCleaner"
        )
    ]
)
