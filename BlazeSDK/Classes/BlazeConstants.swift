import Foundation

enum BlazeConstants {

    static let sdkConfigSuiteName = "in.breeze.blaze.config"
    static let sdkConfigUrl = "https://sdk.breeze.in/core/sdk.json"
    // Address of sdk.json on the CDN. When empty, sdkConfigUrl is used.
    static let cdnConfigUrl = ""
    static let sdkConfigKey = "blazeSdkConfig"
    static let sdkConfigTimeout: TimeInterval = 3
}
