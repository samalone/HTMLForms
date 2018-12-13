// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "HTMLForms",
    dependencies: [
        .package(url: "https://github.com/samalone/SwiftSoup.git", from: "1.7.4"),
    ],
    targets: [
        .target(name: "HTMLForms", dependencies: ["SwiftSoup"]),
        .testTarget(name: "HTMLFormsTests", dependencies: ["SwiftSoup", "HTMLForms"])
    ]
)

