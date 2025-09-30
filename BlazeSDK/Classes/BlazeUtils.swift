import Foundation

func safeParseJson(jsonString: String) -> [String: Any] {

    if jsonString == "" {
        return [:]
    }

    guard let data = jsonString.data(using: .utf8) else {
        print("Error: Could not convert string to data.")
        return [:]
    }

    do {
        if let json = try JSONSerialization.jsonObject(with: data, options: [])
            as? [String: Any]
        {
            return json
        } else {
            print("Error: JSON is not in expected dictionary format.")
        }
    } catch {
        print("Error parsing JSON: \(error.localizedDescription)")
    }
    return [:]
}

func getBaseUrl(payload: [String: Any]) -> String {
    let environment =
        (payload["payload"] as? [String: Any])?["environment"] as? String
        ?? "release"
    if environment == "smbBeta" {
        return "https://app.beta.breezesdk.store"
    } else if environment == "smbRelease" {
        return "https://app.breezesdk.store"
    } else if environment == "beta" {
        return "https://app.beta.breeze.in"
    } else {
        return "https://app.breeze.in"
    }
}

public func isUPIIntentUri(_ url: URL) -> Bool {
    guard
        let scheme = url.scheme?.lowercased(),
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
        let queryItems = components.queryItems,
        !queryItems.isEmpty
    else {
        return false
    }

    let queryParams = Dictionary(
        uniqueKeysWithValues: queryItems.map { item in
            (item.name.lowercased(), item.value ?? "")
        }
    )
    let upiSchemes: Set<String> = [
        "upi", "phonepe", "tez", "gpay", "paytm", "paytmmp", "bhim",
        "amazonpay", "mobikwik", "freecharge", "credpay",
    ]

    let hasPayeeAddress =
        queryParams["pa"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    let hasPayeeName =
        queryParams["pn"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    let hasCurrency =
        queryParams["cu"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    let hasAmount =
        queryParams["am"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    let isKnownScheme = upiSchemes.contains(scheme)

    return hasPayeeAddress && hasPayeeName && hasCurrency && hasAmount && isKnownScheme
}
