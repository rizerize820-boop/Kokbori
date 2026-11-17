import Foundation

struct RemoteConfig: Decodable {
    var launcherVersion: Int
    var updateURL: String
    var news: String
    var manifestURL: String
    var servers: [ServerInfo]

    static let fallback = RemoteConfig(
        launcherVersion: Config.launcherVersion,
        updateURL: "",
        news: "Добро пожаловать в KOKBORI RP.",
        manifestURL: "",
        servers: [
            ServerInfo(name: "Тестовый сервер 01", host: "127.0.0.1", port: 7777),
            ServerInfo(name: "Тестовый сервер 02", host: "127.0.0.1", port: 7778)
        ]
    )

    enum CodingKeys: String, CodingKey {
        case launcherVersion, updateUrl, news, manifestUrl, servers
    }

    init(launcherVersion: Int, updateURL: String, news: String, manifestURL: String, servers: [ServerInfo]) {
        self.launcherVersion = launcherVersion
        self.updateURL = updateURL
        self.news = news
        self.manifestURL = manifestURL
        self.servers = servers
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        launcherVersion = try c.decodeIfPresent(Int.self, forKey: .launcherVersion) ?? Config.launcherVersion
        updateURL = try c.decodeIfPresent(String.self, forKey: .updateUrl) ?? ""
        news = try c.decodeIfPresent(String.self, forKey: .news) ?? ""
        manifestURL = try c.decodeIfPresent(String.self, forKey: .manifestUrl) ?? ""
        let decoded = try c.decodeIfPresent([ServerInfo].self, forKey: .servers) ?? []
        servers = decoded.isEmpty ? Self.fallback.servers : decoded
    }

    static func fetch() async throws -> RemoteConfig {
        let data = try await Http.getData(Config.configURL)
        return try JSONDecoder().decode(RemoteConfig.self, from: data)
    }
}

enum Http {
    static func getData(_ string: String) async throws -> Data {
        guard let url = URL(string: string), url.scheme?.lowercased() == "https", url.host != nil else {
            throw URLError(.unsupportedURL)
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = Config.requestTimeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        guard !data.isEmpty else { throw URLError(.zeroByteResource) }
        return data
    }
}
