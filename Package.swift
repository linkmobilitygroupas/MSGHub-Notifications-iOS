// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MSGHubNotificationsiOS",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "MSGHubNotificationsiOS",
            targets: ["MSGHubNotificationsiOS", "MSGHubInternal"]
        ),
    ],
    dependencies: [
        .package(
            name: "Firebase",
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "8.10.0")
        ),
        .package(
            name: "Alamofire",
            url: "https://github.com/Alamofire/Alamofire.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/devicekit/DeviceKit.git",
            from: "4.0.0"
        ),
    ],
    targets: [
        .target(
            name: "MSGHubNotificationsiOS",
            dependencies: [
                "Alamofire",
                "DeviceKit",
                .product(name: "FirebaseAuth", package: "Firebase"),
                .product(name: "FirebaseMessaging", package: "Firebase"),
            ],
            path: "Sources/MSGHubNotificationsiOS"
        ),
        .binaryTarget(
            name: "MSGHubInternal",
            path: "./Sources/MSGHubInternal.xcframework"
        )
    ]
)
