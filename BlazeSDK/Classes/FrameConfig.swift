import Foundation

enum FrameFailure {
    case configUnavailable
    case invalidAllowedOrigin

    var code: String {
        switch self {
        case .configUnavailable: return "SDK_FRAME_URL_UNAVAILABLE"
        case .invalidAllowedOrigin: return "SDK_INVALID_ALLOWED_ORIGIN"
        }
    }

    var details: String {
        switch self {
        case .configUnavailable: return "sdk.json has no https address for this environment"
        case .invalidAllowedOrigin:
            return "allowedOrigins in sdk.json has an entry that is not an https origin"
        }
    }
}

struct FrameConfig {

    let defaultUrl: String
    let allowedOrigins: Set<String>?

    var isRestricted: Bool {
        return allowedOrigins != nil
    }

    func decide(_ url: URL) -> NavigationDecision {
        guard let allowedOrigins = allowedOrigins else {
            return .allow
        }
        return NavigationPolicy.decide(url: url, allowList: allowedOrigins)
    }

    static func from(payload: [String: Any]) -> FrameConfig {
        return FrameConfig(defaultUrl: getBaseUrl(payload: payload), allowedOrigins: nil)
    }

    static func locked(frameUrl: String, origins: [String]) -> FrameConfig? {
        guard let frameOrigin = NavigationPolicy.originOf(frameUrl) else {
            return nil
        }
        var allowed: Set<String> = [frameOrigin]
        for origin in origins {
            guard let listed = NavigationPolicy.bareOriginOf(origin) else {
                return nil
            }
            allowed.insert(listed)
        }
        return FrameConfig(defaultUrl: frameUrl, allowedOrigins: allowed)
    }
}
