import Foundation
import Network
import Darwin

enum SampQueryError: LocalizedError {
    case resolveFailed, timeout, badResponse
    var errorDescription: String? {
        switch self {
        case .resolveFailed: return "Не удалось определить IP сервера."
        case .timeout: return "Сервер не ответил."
        case .badResponse: return "Некорректный ответ сервера."
        }
    }
}

enum SampQuery {
    static func query(_ server: ServerInfo, timeout: TimeInterval = 2) async throws -> ServerInfo {
        guard (1...65535).contains(server.port) else { throw SampQueryError.badResponse }
        let ip = try await Task.detached(priority: .utility) { try resolveIPv4(server.host) }.value
        var packet = Data("SAMP".utf8)
        packet.append(contentsOf: ip)
        packet.append(UInt8(server.port & 0xff))
        packet.append(UInt8((server.port >> 8) & 0xff))
        packet.append(UInt8(ascii: "i"))
        let host = ip.map(String.init).joined(separator: ".")
        let (data, ping) = try await exchange(host: host, port: server.port, packet: packet, timeout: timeout)
        return try parse(data, server: server, ping: ping)
    }

    private final class Gate: @unchecked Sendable {
        private let lock = NSLock()
        private var done = false
        func finish(_ action: () -> Void) {
            lock.lock()
            defer { lock.unlock() }
            guard !done else { return }
            done = true
            action()
        }
    }

    private static func exchange(host: String, port: Int, packet: Data, timeout: TimeInterval) async throws -> (Data, Int) {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { throw SampQueryError.badResponse }
        let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .udp)
        let gate = Gate()
        return try await withCheckedThrowingContinuation { continuation in
            var timer: DispatchWorkItem?
            func complete(_ result: Result<(Data, Int), Error>) {
                gate.finish {
                    timer?.cancel()
                    connection.cancel()
                    continuation.resume(with: result)
                }
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let started = DispatchTime.now()
                    connection.send(content: packet, completion: .contentProcessed { error in
                        if let error { complete(.failure(error)); return }
                        connection.receiveMessage { data, _, _, error in
                            if let error { complete(.failure(error)); return }
                            guard let data, !data.isEmpty else { complete(.failure(SampQueryError.badResponse)); return }
                            let elapsed = DispatchTime.now().uptimeNanoseconds - started.uptimeNanoseconds
                            complete(.success((data, Int(elapsed / 1_000_000))))
                        }
                    })
                case .failed(let error): complete(.failure(error))
                default: break
                }
            }
            timer = DispatchWorkItem { complete(.failure(SampQueryError.timeout)) }
            connection.start(queue: .global(qos: .utility))
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout, execute: timer!)
        }
    }

    private static func resolveIPv4(_ host: String) throws -> [UInt8] {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_DGRAM
        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &result) == 0, let first = result else {
            throw SampQueryError.resolveFailed
        }
        defer { freeaddrinfo(result) }
        guard let address = first.pointee.ai_addr else { throw SampQueryError.resolveFailed }
        return address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
            var value = $0.pointee.sin_addr.s_addr
            return withUnsafeBytes(of: &value) { Array($0) }
        }
    }

    private static func parse(_ data: Data, server: ServerInfo, ping: Int) throws -> ServerInfo {
        let b = [UInt8](data)
        guard b.count >= 20, Array(b[0..<4]) == Array("SAMP".utf8) else { throw SampQueryError.badResponse }
        var offset = 12 // header (11 bytes) + password flag
        let online = read16(b, &offset)
        let maximum = read16(b, &offset)
        let length = Int(read32(b, &offset))
        guard length >= 0, offset <= b.count, length <= b.count - offset else { throw SampQueryError.badResponse }
        let nameData = Data(b[offset..<(offset + length)])
        let name = String(data: nameData, encoding: .windowsCP1251) ?? String(decoding: nameData, as: UTF8.self)
        var result = server
        result.online = online
        result.maxOnline = maximum
        result.pingMs = ping
        result.hostname = name
        return result
    }

    private static func read16(_ b: [UInt8], _ offset: inout Int) -> Int {
        let value = Int(b[offset]) | Int(b[offset + 1]) << 8
        offset += 2
        return value
    }

    private static func read32(_ b: [UInt8], _ offset: inout Int) -> UInt32 {
        let value = UInt32(b[offset]) | UInt32(b[offset + 1]) << 8 | UInt32(b[offset + 2]) << 16 | UInt32(b[offset + 3]) << 24
        offset += 4
        return value
    }
}
