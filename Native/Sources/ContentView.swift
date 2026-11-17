import SwiftUI

private enum Theme {
    static let background = Color(red: 0.035, green: 0.04, blue: 0.05)
    static let panel = Color(red: 0.085, green: 0.09, blue: 0.10)
    static let gold = Color(red: 0.88, green: 0.68, blue: 0.28)
    static let aqua = Color(red: 0.20, green: 0.78, blue: 0.72)
    static let muted = Color.white.opacity(0.58)
}

struct ContentView: View {
    @StateObject private var model = LauncherViewModel()
    @State private var tab = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        switch tab {
                        case 0: home
                        case 1: serverList
                        case 2: placeholder("КАРТА SAN ANDREAS", icon: "map.fill", text: "Интерактивная карта пока не подключена.")
                        case 3: profile
                        default: settings
                        }
                    }
                    .padding(18)
                }
                tabBar
            }
        }
        .task { await model.refresh() }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("KOKBORI").font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(Theme.gold)
                Text("ROLEPLAY • iOS LAUNCHER").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(Theme.muted)
            }
            Spacer()
            Button { Task { await model.refresh() } } label: {
                Image(systemName: "arrow.clockwise").foregroundStyle(Theme.aqua).padding(12).background(Theme.panel, in: Circle())
            }
            .accessibilityLabel("Обновить")
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 10)
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("SAN ANDREAS").font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(3).foregroundStyle(Theme.aqua)
                Text("ТВОЯ ИГРА.\nТВОИ ПРАВИЛА.").font(.system(size: 29, weight: .black, design: .rounded))
                Text("KOKBORI ROLEPLAY").font(.system(size: 10, weight: .bold)).tracking(2).foregroundStyle(Theme.gold)
            }
            .frame(maxWidth: .infinity, minHeight: 155, alignment: .leading)
            .padding(22)
            .background(LinearGradient(colors: [Color(red: 0.18, green: 0.17, blue: 0.12), Theme.panel], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))

            title("НОВОСТИ")
            card { Text(model.news.isEmpty ? "Пока нет новостей." : model.news).font(.system(size: 14)).foregroundStyle(.white.opacity(0.85)) }

            title("ВЫБРАННЫЙ СЕРВЕР")
            if let server = model.selectedServer { serverCard(server, selectable: false) }
            else { card { Text("Серверы не добавлены.").foregroundStyle(Theme.muted) } }

            Button { Task { await model.play() } } label: {
                HStack {
                    if model.isBusy { ProgressView().tint(.black) } else { Image(systemName: "play.fill") }
                    Text(model.isBusy ? "ПОДГОТОВКА…" : "ИГРАТЬ").font(.system(size: 15, weight: .black)).tracking(2)
                }
                .foregroundStyle(.black).frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(Theme.gold, in: RoundedRectangle(cornerRadius: 15))
            }
            .disabled(model.isBusy)
            statusLine
        }
    }

    private var serverList: some View {
        VStack(alignment: .leading, spacing: 13) {
            title("ИГРОВЫЕ СЕРВЕРЫ")
            ForEach(model.servers) { server in
                Button { model.selectedID = server.id } label: { serverCard(server, selectable: true) }
                    .buttonStyle(.plain)
            }
        }
    }

    private var profile: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("ПРОФИЛЬ ИГРОКА")
            card {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 52)).foregroundStyle(Theme.gold).frame(maxWidth: .infinity)
                Text("ИГРОВОЙ НИК").font(.system(size: 10, weight: .bold)).tracking(2).foregroundStyle(Theme.muted)
                TextField("Name_Surname", text: $model.nick)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .padding(13).background(Theme.background, in: RoundedRectangle(cornerRadius: 11))
            }
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("НАСТРОЙКИ")
            card {
                row("Версия лаунчера", value: "\(Config.launcherVersion).0")
                Divider().overlay(.white.opacity(0.08))
                row("Минимальная iOS", value: "16.0")
                Divider().overlay(.white.opacity(0.08))
                row("Игровой клиент", value: "Внешний")
                Text("Требуется установленный клиент с URL-схемой crmpclient.").font(.system(size: 11)).foregroundStyle(Theme.muted)
            }
        }
    }

    private var statusLine: some View {
        HStack(spacing: 8) {
            Circle().fill(statusColor).frame(width: 7, height: 7)
            Text(model.status).font(.system(size: 11)).foregroundStyle(Theme.muted)
            Spacer()
            if model.isBusy { Text("\(Int(model.progress * 100))%").font(.caption.monospacedDigit()) }
        }
    }

    private var statusColor: Color {
        switch model.statusKind {
        case .muted: return Theme.muted
        case .ok: return Theme.aqua
        case .warn: return Theme.gold
        case .bad: return .red
        }
    }

    private var tabBar: some View {
        HStack {
            tabItem("house.fill", "Главная", 0)
            tabItem("server.rack", "Серверы", 1)
            tabItem("map.fill", "Карта", 2)
            tabItem("person.fill", "Профиль", 3)
            tabItem("gearshape.fill", "Настройки", 4)
        }
        .padding(.top, 10).padding(.bottom, 6).background(Theme.panel)
    }

    private func tabItem(_ icon: String, _ name: String, _ index: Int) -> some View {
        Button { tab = index } label: {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 15, weight: .semibold))
                Text(name).font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(tab == index ? Theme.gold : Theme.muted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func title(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .black, design: .monospaced)).tracking(2).foregroundStyle(Theme.gold)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 17))
    }

    private func serverCard(_ server: ServerInfo, selectable: Bool) -> some View {
        HStack(spacing: 11) {
            Image(systemName: "server.rack").foregroundStyle(server.isOnline ? Theme.aqua : Theme.gold)
                .frame(width: 40, height: 40).background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(server.name).font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                Text("\(server.host):\(server.port)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted)
                Text(server.isOnline ? "\(server.online)/\(server.maxOnline) игроков" : "Нет ответа / тестовый сервер")
                    .font(.system(size: 10)).foregroundStyle(Theme.muted)
            }
            Spacer()
            if server.isOnline { Text("\(server.pingMs) ms").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Theme.aqua) }
            if selectable { Image(systemName: model.selectedID == server.id ? "checkmark.circle.fill" : "circle").foregroundStyle(Theme.gold) }
        }
        .padding(13).background(Theme.panel, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(selectable && model.selectedID == server.id ? Theme.gold : .clear, lineWidth: 1))
    }

    private func placeholder(_ heading: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            title(heading)
            card {
                Image(systemName: icon).font(.system(size: 48)).foregroundStyle(Theme.aqua).frame(maxWidth: .infinity).padding(.vertical, 22)
                Text(text).font(.system(size: 13)).foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
            }
        }
    }

    private func row(_ title: String, value: String) -> some View {
        HStack {
            Text(title).font(.system(size: 13)).foregroundStyle(.white.opacity(0.85))
            Spacer()
            Text(value).font(.system(size: 11)).foregroundStyle(Theme.muted)
        }
    }
}
