import Foundation

/// A `SessionStore` backed by two plain JSON files in a directory —
/// no database, matching the simplicity called for in the Technical
/// Plan §5. `directory` is injected so tests can point this at a
/// temp directory instead of the real Application Support path.
public final class JSONFileSessionStore: SessionStore, @unchecked Sendable {
    private let historyURL: URL
    private let inProgressURL: URL
    private let lock = NSLock()

    public init(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.historyURL = directory.appendingPathComponent("sessions.json")
        self.inProgressURL = directory.appendingPathComponent("in-progress.json")
    }

    public func save(_ session: Session) throws {
        lock.lock()
        defer { lock.unlock() }

        var history = try readHistory()
        history.removeAll { $0.id == session.id }
        history.insert(session, at: 0) // most-recent-first
        try write(history, to: historyURL)

        if FileManager.default.fileExists(atPath: inProgressURL.path) {
            try FileManager.default.removeItem(at: inProgressURL)
        }
    }

    public func loadHistory() throws -> [Session] {
        lock.lock()
        defer { lock.unlock() }
        return try readHistory()
    }

    @discardableResult
    public func clearHistory(_ scope: HistoryClearScope, asOf now: Date) throws -> Int {
        lock.lock()
        defer { lock.unlock() }

        let history = try readHistory()
        let toRemove = Set(history.matching(scope, asOf: now).map(\.id))
        guard !toRemove.isEmpty else { return 0 } // nothing matched — not an error

        let remaining = history.filter { !toRemove.contains($0.id) }
        // Atomic write: if this throws, sessions.json is left intact and
        // this method has mutated nothing — the "never a partial delete"
        // guarantee. Only sessions.json is touched; the in-progress
        // marker file is never opened here.
        try write(remaining, to: historyURL)
        return toRemove.count
    }

    public func markInProgress(_ session: Session) throws {
        lock.lock()
        defer { lock.unlock() }
        try write(session, to: inProgressURL)
    }

    public func clearInProgressMarker() throws {
        lock.lock()
        defer { lock.unlock() }
        if FileManager.default.fileExists(atPath: inProgressURL.path) {
            try FileManager.default.removeItem(at: inProgressURL)
        }
    }

    public func loadAbandonedInProgressSession() throws -> Session? {
        lock.lock()
        defer { lock.unlock() }
        guard FileManager.default.fileExists(atPath: inProgressURL.path) else { return nil }
        let data = try Data(contentsOf: inProgressURL)
        return try JSONDecoder().decode(Session.self, from: data)
    }

    // MARK: - Private

    private func readHistory() throws -> [Session] {
        guard FileManager.default.fileExists(atPath: historyURL.path) else { return [] }
        let data = try Data(contentsOf: historyURL)
        if data.isEmpty { return [] }
        return try JSONDecoder().decode([Session].self, from: data)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }
}
