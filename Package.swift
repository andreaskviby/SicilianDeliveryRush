// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SicilianDeliveryRush",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SicilianDeliveryRush",
            targets: ["SicilianDeliveryRush"]
        ),
    ],
    targets: [
        .target(
            name: "SicilianDeliveryRush",
            path: "SicilianDeliveryRush"
        ),
    ]
)
