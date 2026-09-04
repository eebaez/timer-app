import Foundation
import TimerCore

/// In-memory `SessionStore` for exercising `AppModel` without touching
/// disk. Not thread-safe — tests drive it from the main actor only.
final class FakeSessionStore: SessionStore, @unchecked Sendable {
    var history: [Session]
    var abandoned: Session?

    /// When true, the next `clearHistory` throws and leaves `history`
    /// untouched — models the store's all-or-nothing failure.
    var failNextClear = false

    private(set) var clearCallCount = 0
    private(set) var lastClearScope: HistoryClearScope?

    struct ClearError: Error {}

    init(history: [Session] = [], abandoned: Session? = nil) {
        self.history = history
        self.abandoned = abandoned
    }

    func save(_ session: Session) throws {
        history.removeAll { $0.id == session.id }
        history.insert(session, at: 0)
    }

    func loadHistory() throws -> [Session] { history }

    func clearHistory(_ scope: HistoryClearScope, asOf now: Date) throws -> Int {
        clearCallCount += 1
        lastClearScope = scope
        if failNextClear {
            failNextClear = false
            throw ClearError()
        }
        let removed = history.matching(scope, asOf: now).map(\.id)
        let removedSet = Set(removed)
        history.removeAll { removedSet.contains($0.id) }
        return removed.count
    }

    func markInProgress(_ session: Session) throws { abandoned = session }
    func clearInProgressMarker() throws { abandoned = nil }
    func loadAbandonedInProgressSession() throws -> Session? { abandoned }
}
