import Foundation

struct ServerInfo: Identifiable, Hashable, Codable {
    var name: String
    var host: String
    var port: Int
    var online = 0
    var maxOnline = 0
    var pingMs = -1
    var hostname = ""

    var id: String { "\(host):\(port)" }
    var isOnline: Bool { pingMs >= 0 }

    enum CodingKeys: String, CodingKey { case name, host, port }
}

struct GameFile: Decodable {
    let path: String
    let url: String
    let sha256: String
    let size: Int64
}
