import Foundation
import SwiftUI

enum StatusKind { case muted, ok, warn, bad }

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var servers = RemoteConfig.fallback.servers
    @Published var selectedID: String?
    @Published var nick: String {
        didSet { UserDefaults.standard.set(nick, forKey: Self.nickKey) }
    }
    @Published var news = RemoteConfig.fallback.news
    @Published var updateURL: URL?
    @Published var progress = 0.0
    @Published var status = "Готов к запуску"
    @Published var statusKind: StatusKind = .muted
    @Published var isBusy = false

    private var config = RemoteConfig.fallback
    private var isRefreshing = false
    private static let nickKey = "kokbori.player.nickname"

    init() {
        nick = UserDefaults.standard.string(forKey: Self.nickKey) ?? ""
        selectedID = servers.first?.id
    }

    var selectedServer: ServerInfo? { servers.first { $0.id == selectedID } }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            config = try await RemoteConfig.fetch()
        } catch {
            config = .fallback
            setStatus("Не удалось загрузить конфиг. Используется резервный список.", .warn)
        }

        news = config.news
        if config.launcherVersion > Config.launcherVersion,
           let url = URL(string: config.updateURL),
           url.scheme?.lowercased() == "https", url.host != nil {
            updateURL = url
        } else {
            updateURL = nil
        }

        let oldID = selectedID
        servers = config.servers
        selectedID = oldID.flatMap { id in servers.contains(where: { $0.id == id }) ? id : nil } ?? servers.first?.id

        let snapshot = servers
        let result = await withTaskGroup(of: (Int, ServerInfo).self) { group in
            for (index, server) in snapshot.enumerated() {
                group.addTask { (index, (try? await SampQuery.query(server)) ?? server) }
            }
            var output = snapshot
            for await (index, value) in group { output[index] = value }
            return output
        }
        servers = result
    }

    func play() async {
        guard !isBusy else { return }
        guard let server = selectedServer else { setStatus("Выберите сервер.", .warn); return }
        let value = nick.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.range(of: "^[A-Za-z]{2,}_[A-Za-z]{2,}$", options: .regularExpression) != nil else {
            setStatus("Ник должен быть вида Name_Surname.", .warn)
            return
        }

        isBusy = true
        progress = 0
        defer { isBusy = false }
        do {
            if !config.manifestURL.isEmpty {
                setStatus("Проверка файлов…", .muted)
                let updater = try Updater()
                let manifest = try await updater.fetchManifest(config.manifestURL)
                let outdated = try await updater.findOutdated(manifest)
                if !outdated.isEmpty {
                    try await updater.download(outdated) { [weak self] amount, filename in
                        Task { @MainActor in
                            self?.progress = amount
                            self?.setStatus(filename.isEmpty ? "Загрузка завершена." : "Загрузка \(filename)", .muted)
                        }
                    }
                }
            }
            setStatus("Запуск игрового клиента…", .ok)
            try await GameLauncher.launch(nick: value, server: server)
        } catch {
            setStatus(error.localizedDescription, .bad)
        }
    }

    private func setStatus(_ text: String, _ kind: StatusKind) {
        status = text
        statusKind = kind
    }
}
