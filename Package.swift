// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BlazeSDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "BlazeSDK", targets: ["BlazeSDK"])
    ],
    targets: [
        .target(
            name: "BlazeSDK",
            path: "BlazeSDK",
            exclude: ["Assets", "Classes/.gitkeep"],
            sources: ["Classes"],
            resources: [.copy("Resources/PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "BlazeSDKTests",
            dependencies: ["BlazeSDK"],
            path: "Example/Tests",
            exclude: ["Info.plist"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
