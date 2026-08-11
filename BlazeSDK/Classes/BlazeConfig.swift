import Foundation

final class BlazeConfig {

    static let shared = BlazeConfig()

    private let queue = DispatchQueue(label: "in.breeze.blaze.config")
    private let defaults = UserDefaults(suiteName: BlazeConstants.sdkConfigSuiteName)

    private var cachedConfig: [String: Any]?
    private var hasFetched: Bool = false

    private init() {}

    func resolveFrameUrl(
        service: String, environment: String,
        completion: @escaping (String?) -> Void
    ) {
        queue.async {
            if let config = self.cachedConfig {
                self.complete(completion, config, service, environment)
                self.refresh()
                return
            }

            if let persistedConfig = self.loadPersistedConfig() {
                self.cachedConfig = persistedConfig
                self.complete(completion, persistedConfig, service, environment)
                self.refresh()
                return
            }

            self.fetchAndStore { config in
                self.complete(completion, config, service, environment)
            }
        }
    }

    private func refresh() {
        if hasFetched {
            return
        }
        fetchAndStore(completion: nil)
    }

    private func fetchAndStore(completion: (([String: Any]?) -> Void)?) {
        if hasFetched {
            completion?(cachedConfig)
            return
        }
        hasFetched = true

        guard let url = URL(string: BlazeConstants.sdkConfigUrl) else {
            completion?(cachedConfig)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = BlazeConstants.sdkConfigTimeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            let config = BlazeConfig.parseConfig(data: data, response: response, error: error)
            self.queue.async {
                if let config = config {
                    self.persistConfig(config)
                    self.cachedConfig = config
                }
                completion?(self.cachedConfig)
            }
        }.resume()
    }

    private static func parseConfig(
        data: Data?, response: URLResponse?, error: Error?
    ) -> [String: Any]? {
        if let error = error {
            print("BlazeSDK: config: \(error.localizedDescription)")
            return nil
        }

        if let statusCode = (response as? HTTPURLResponse)?.statusCode,
            !(200..<300).contains(statusCode)
        {
            print("BlazeSDK: config: Unexpected response \(statusCode)")
            return nil
        }

        guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data),
            let config = json as? [String: Any],
            config["services"] is [String: Any]
        else {
            print("BlazeSDK: config: Malformed config")
            return nil
        }
        return config
    }

    private func loadPersistedConfig() -> [String: Any]? {
        guard let data = defaults?.data(forKey: BlazeConstants.sdkConfigKey),
            let json = try? JSONSerialization.jsonObject(with: data),
            let config = json as? [String: Any],
            config["services"] is [String: Any]
        else {
            return nil
        }
        return config
    }

    private func persistConfig(_ config: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: config) else {
            return
        }
        defaults?.set(data, forKey: BlazeConstants.sdkConfigKey)
    }

    private func complete(
        _ completion: @escaping (String?) -> Void,
        _ config: [String: Any]?, _ service: String, _ environment: String
    ) {
        let frameUrl = config.flatMap {
            BlazeConfig.frameUrl(in: $0, service: service, environment: environment)
        }
        DispatchQueue.main.async {
            completion(frameUrl)
        }
    }

    private static func frameUrl(
        in config: [String: Any], service: String, environment: String
    ) -> String? {
        if service.isEmpty || environment.isEmpty {
            return nil
        }

        guard let services = config["services"] as? [String: Any],
            let serviceConfig = services[service] as? [String: Any],
            let frameUrls = serviceConfig["frameUrls"] as? [String: Any],
            let frameUrl = frameUrls[environment] as? String
        else {
            return nil
        }

        if !frameUrl.lowercased().hasPrefix("https://") {
            return nil
        }
        return frameUrl
    }
}
