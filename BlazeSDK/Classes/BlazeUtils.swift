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
    if environment == "beta" {
        return "https://app.beta.breeze.in"
    } else {
        return "https://app.breeze.in"
    }
}
