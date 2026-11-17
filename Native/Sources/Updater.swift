import Foundation
import CryptoKit

enum UpdaterError: LocalizedError {
    case badPath(String), badURL(String), badStatus(String), hashMismatch(String), invalidSize(String)
    var errorDescription: String? {
        switch self {
        case .badPath(let p): return "Недопустимый путь: \(p)"
        case .badURL(let u): return "Недопустимая ссылка: \(u)"
        case .badStatus(let p): return "Ошибка загрузки: \(p)"
        case .hashMismatch(let p): return "Хэш не совпал: \(p)"
        case .invalidSize(let p): return "Неверный размер файла: \(p)"
        }
    }
}

final class Updater: @unchecked Sendable {
    let root: URL
    private let fm = FileManager.default

    init() throws {
        let base = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = base.appendingPathComponent(Config.gameDirName, isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var excluded = folder
        try? excluded.setResourceValues(values)
        root = folder.standardizedFileURL
    }

    func fetchManifest(_ url: String) async throws -> [GameFile] {
        let data = try await Http.getData(url)
        let manifest = try JSONDecoder().decode([GameFile].self, from: data)
        for file in manifest { try validate(file) }
        return manifest
    }

    func findOutdated(_ manifest: [GameFile]) async throws -> [GameFile] {
        for file in manifest { try validate(file) }
        return try await Task.detached(priority: .utility) { [self] in
            try manifest.filter { file in
                try Task.checkCancellation()
                let target = try resolve(file.path)
                guard fm.fileExists(atPath: target.path) else { return true }
                return try Self.sha256(of: target).caseInsensitiveCompare(file.sha256) != .orderedSame
            }
        }.value
    }

    func download(_ files: [GameFile], onProgress: @escaping @Sendable (Double, String) -> Void) async throws {
        for file in files { try validate(file) }
        let total = files.reduce(Int64(0)) { $0 + $1.size }
        var completed: Int64 = 0

        for (index, file) in files.enumerated() {
            try Task.checkCancellation()
            onProgress(fraction(completed, total, index, files.count), file.path)
            let target = try resolve(file.path)
            guard let url = URL(string: file.url) else { throw UpdaterError.badURL(file.url) }
            var request = URLRequest(url: url)
            request.timeoutInterval = 120
            let (temporary, response) = try await URLSession.shared.download(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                try? fm.removeItem(at: temporary)
                throw UpdaterError.badStatus(file.path)
            }

            let attrs = try fm.attributesOfItem(atPath: temporary.path)
            let actualSize = (attrs[.size] as? NSNumber)?.int64Value ?? -1
            guard actualSize == file.size else {
                try? fm.removeItem(at: temporary)
                throw UpdaterError.invalidSize(file.path)
            }
            let actualHash = try await Task.detached(priority: .utility) { try Self.sha256(of: temporary) }.value
            guard actualHash.caseInsensitiveCompare(file.sha256) == .orderedSame else {
                try? fm.removeItem(at: temporary)
                throw UpdaterError.hashMismatch(file.path)
            }

            try fm.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: target.path) { try fm.removeItem(at: target) }
            try fm.moveItem(at: temporary, to: target)
            completed += file.size
            onProgress(fraction(completed, total, index + 1, files.count), file.path)
        }
        onProgress(1, "")
    }

    private func validate(_ file: GameFile) throws {
        guard file.size > 0 else { throw UpdaterError.invalidSize(file.path) }
        guard file.sha256.count == 64, file.sha256.allSatisfy({ $0.isHexDigit }) else {
            throw UpdaterError.hashMismatch(file.path)
        }
        _ = try resolve(file.path)
        guard let url = URL(string: file.url), url.scheme?.lowercased() == "https", url.host != nil else {
            throw UpdaterError.badURL(file.url)
        }
    }

    private func resolve(_ path: String) throws -> URL {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard !path.isEmpty, !path.hasPrefix("/"), !path.contains("\\"),
              !components.isEmpty,
              !components.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." }) else {
            throw UpdaterError.badPath(path)
        }
        let target = root.appendingPathComponent(path).standardizedFileURL
        let prefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
        guard target.path.hasPrefix(prefix) else { throw UpdaterError.badPath(path) }
        return target
    }

    private func fraction(_ done: Int64, _ total: Int64, _ index: Int, _ count: Int) -> Double {
        if total > 0 { return min(1, Double(done) / Double(total)) }
        return count > 0 ? Double(index) / Double(count) : 1
    }

    static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            let data = try handle.read(upToCount: 1 << 20) ?? Data()
            if data.isEmpty { break }
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
