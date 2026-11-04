import Foundation

enum NavigationDecision {
    case allow
    case block
}

enum NavigationPolicy {

    private static let https = "https"
    private static let defaultHttpsPort = 443
    private static let aboutBlank = "about:blank"

    static func decide(url: URL, allowList: Set<String>) -> NavigationDecision {
        if allowList.isEmpty {
            return .block
        }
        if url.absoluteString.lowercased() == aboutBlank {
            return .allow
        }
        guard let origin = originOf(url.absoluteString), allowList.contains(origin) else {
            return .block
        }
        return .allow
    }

    static func originOf(_ url: String) -> String? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let components = URLComponents(string: trimmed),
            components.scheme?.lowercased() == https
        else {
            return nil
        }
        return originOf(components)
    }

    static func bareOriginOf(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let schemeEnd = trimmed.range(of: "://") else {
            return nil
        }
        if trimmed[schemeEnd.upperBound...].contains(where: { "/?#@\\".contains($0) }) {
            return nil
        }
        return originOf(trimmed)
    }

    private static func originOf(_ components: URLComponents) -> String? {
        guard let host = components.host?.lowercased(), !host.isEmpty else {
            return nil
        }
        var port = ""
        if let value = components.port, value != defaultHttpsPort {
            port = ":\(value)"
        }
        return "\(https)://\(host)\(port)"
    }
}
