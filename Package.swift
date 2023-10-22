// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Readability",
	platforms: [
		.macOS(.v14),
		.iOS(.v17)
	],
    products: [
        .library(
            name: "Readability",
            targets: ["Readability"]),
    ],
    targets: [
        .target(
            name: "Readability",
			resources: [.copy("readability.js")]
		),
        .testTarget(
            name: "ReadabilityTests",
            dependencies: ["Readability"]),
    ]
)
