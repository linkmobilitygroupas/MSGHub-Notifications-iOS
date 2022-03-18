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
        .package(
           name: "Firebase",
           url: "https://github.com/firebase/firebase-ios-sdk.git",
           .upToNextMajor(from: "8.10.0")
         ),
        .package(name: "Alamofire",url: "https://github.com/Alamofire/Alamofire.git", branch: "master"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "MSGHub Notifications iOS",
            dependencies: [
                "Alamofire", "DeviceKit",
                .product(name: "FirebaseAuth", package: "Firebase"),
                .product(name: "FirebaseMessaging", package: "Firebase"),
            ]
        ),
        .binaryTarget(
            name: "MSGHubInternal",
            path: "./Sources/MSGHubInternal.xcframework"
        )
    ]
)
