// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MSGHub Notifications iOS",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "MSGHub Notifications iOS",
            targets: ["MSGHub Notifications iOS", "MSGHubInternal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "4.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "8.13.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.5.0")),
    ],
    targets: [
        .target(
            name: "MSGHub Notifications iOS",
            dependencies: [
                "Alamofire", "DeviceKit",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            ]
        ),
        .binaryTarget(
            name: "MSGHubInternal",
            path: "./Sources/MSGHubInternal.xcframework"
        )
    ]
)
