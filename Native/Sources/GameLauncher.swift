import UIKit

enum GameLauncherError: LocalizedError {
    case invalidURL, clientNotInstalled, launchFailed
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Некорректные данные запуска."
        case .clientNotInstalled: return "Игровой клиент не установлен."
        case .launchFailed: return "Не удалось открыть игровой клиент."
        }
    }
}

enum GameLauncher {
    static func makeURL(nick: String, server: ServerInfo) -> URL? {
        let name = nick.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !server.host.isEmpty, (1...65535).contains(server.port) else { return nil }
        var c = URLComponents()
        c.scheme = Config.gameURLScheme
        c.host = "connect"
        c.queryItems = [
            URLQueryItem(name: "nickname", value: name),
            URLQueryItem(name: "host", value: server.host),
            URLQueryItem(name: "port", value: String(server.port))
        ]
        return c.url
    }

    @MainActor
    static func isInstalled() -> Bool {
        guard let url = URL(string: "\(Config.gameURLScheme)://connect") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    @MainActor
    static func launch(nick: String, server: ServerInfo) async throws {
        guard let url = makeURL(nick: nick, server: server) else { throw GameLauncherError.invalidURL }
        guard isInstalled() else { throw GameLauncherError.clientNotInstalled }
        guard await UIApplication.shared.open(url, options: [:]) else { throw GameLauncherError.launchFailed }
    }
}
