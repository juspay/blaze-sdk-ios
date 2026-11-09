import Foundation

private final class RedirectBlocker: NSObject, URLSessionTaskDelegate {

    func urlSession(
        _ session: URLSession, task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

struct RemoteFrame {
    let frameUrl: String?
    let allowedOrigins: [String]?
}

final class BlazeConfig {

    private struct ConfigFile {
        let url: String
        let defaultsKey: String
    }

    static let shared = BlazeConfig()

    private let queue = DispatchQueue(label: "in.breeze.blaze.config")
    private let defaults = UserDefaults(suiteName: BlazeConstants.sdkConfigSuiteName)
    private let session = URLSession(
        configuration: .default, delegate: RedirectBlocker(), delegateQueue: nil)
    private let configFile =
        BlazeConstants.cdnConfigUrl.isEmpty
        ? ConfigFile(url: BlazeConstants.sdkConfigUrl, defaultsKey: BlazeConstants.sdkConfigKey)
        : ConfigFile(
            url: BlazeConstants.cdnConfigUrl,
            defaultsKey: "\(BlazeConstants.sdkConfigKey):\(BlazeConstants.cdnConfigUrl)")

    private var cachedConfigs: [String: [String: Any]] = [:]
    private var fetchedUrls: Set<String> = []

    private init() {}

    func resolveFrame(
        service: String, environment: String,
        completion: @escaping (RemoteFrame?) -> Void
    ) {
        load(configFile) { config in
            let remote = config.map {
                RemoteFrame(
                    frameUrl: BlazeConfig.frameUrl(in: $0, service: service, environment: environment),
                    allowedOrigins: BlazeConfig.allowedOrigins(
                        in: $0, service: service, environment: environment))
            }
            DispatchQueue.main.async {
                completion(remote)
            }
        }
    }

    private func load(_ file: ConfigFile, completion: @escaping ([String: Any]?) -> Void) {
        queue.async {
            if let config = self.cachedConfigs[file.url] {
                completion(config)
                self.refresh(file)
                return
            }

            if let persistedConfig = self.loadPersistedConfig(file) {
                self.cachedConfigs[file.url] = persistedConfig
                completion(persistedConfig)
                self.refresh(file)
                return
            }

            self.fetchAndStore(file, completion: completion)
        }
    }

    private func refresh(_ file: ConfigFile) {
        if fetchedUrls.contains(file.url) {
            return
        }
        fetchAndStore(file, completion: nil)
    }

    private func fetchAndStore(_ file: ConfigFile, completion: (([String: Any]?) -> Void)?) {
        if fetchedUrls.contains(file.url) {
            completion?(cachedConfigs[file.url])
            return
        }
        fetchedUrls.insert(file.url)

        guard let url = URL(string: file.url) else {
            completion?(cachedConfigs[file.url])
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = BlazeConstants.sdkConfigTimeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        session.dataTask(with: request) { data, response, error in
            let config = BlazeConfig.parseConfig(
                data: data, response: response, error: error)
            self.queue.async {
                if let config = config {
                    self.persistConfig(config, file)
                    self.cachedConfigs[file.url] = config
                } else {
                    self.fetchedUrls.remove(file.url)
                }
                completion?(self.cachedConfigs[file.url])
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

        if response?.mimeType?.lowercased() != "application/json" {
            print("BlazeSDK: config: Unexpected content type \(response?.mimeType ?? "")")
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

    private func loadPersistedConfig(_ file: ConfigFile) -> [String: Any]? {
        guard let data = defaults?.data(forKey: file.defaultsKey),
            let json = try? JSONSerialization.jsonObject(with: data),
            let config = json as? [String: Any],
            config["services"] is [String: Any]
        else {
            return nil
        }
        return config
    }

    private func persistConfig(_ config: [String: Any], _ file: ConfigFile) {
        guard let data = try? JSONSerialization.data(withJSONObject: config) else {
            return
        }
        defaults?.set(data, forKey: file.defaultsKey)
    }

    private static func serviceConfig(
        in config: [String: Any], service: String
    ) -> [String: Any]? {
        return (config["services"] as? [String: Any])?[service] as? [String: Any]
    }

    private static func frameUrl(
        in config: [String: Any], service: String, environment: String
    ) -> String? {
        if service.isEmpty || environment.isEmpty {
            return nil
        }

        guard let frameUrls = serviceConfig(in: config, service: service)?["frameUrls"] as? [String: Any],
            let frameUrl = frameUrls[environment] as? String
        else {
            return nil
        }

        if !frameUrl.lowercased().hasPrefix("https://") {
            return nil
        }
        return frameUrl
    }

    private static func allowedOrigins(
        in config: [String: Any], service: String, environment: String
    ) -> [String]? {
        let origins = serviceConfig(in: config, service: service)?["allowedOrigins"]
            as? [String: Any]
        return (origins?[environment] as? [Any])?.map { $0 as? String ?? "" }
    }
}
