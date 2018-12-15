// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "HTMLForms",
    products: [
        .library(name: "HTMLForms", targets: ["HTMLForms"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "HTMLForms", dependencies: []),
        .testTarget(name: "HTMLFormsTests", dependencies: ["HTMLForms"])
    ]
)

