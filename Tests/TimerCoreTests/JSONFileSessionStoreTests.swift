import Foundation
import Testing
@testable import TimerCore

struct JSONFileSessionStoreTests {
    private func makeStore() throws -> JSONFileSessionStore {
        try JSONFileSessionStore(directory: makeDir())
    }

    private func makeDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("InterviewTimerTests-\(UUID().uuidString)")
    }

    private func completed(id: UUID = UUID(), startedAt: Date) -> Session {
        var s = Session(id: id, startedAt: startedAt)
        s.status = .completed
        return s
    }

    @Test func savedSessionRoundTripsThroughHistory() throws {
        let store = try makeStore()
        var session = Session()
        session.status = .completed

        try store.save(session)
        let history = try store.loadHistory()

        #expect(history.count == 1)
        #expect(history.first?.id == session.id)
        #expect(history.first?.status == .completed)
    }

    @Test func historyIsMostRecentFirst() throws {
        let store = try makeStore()
        let first = Session(startedAt: Date(timeIntervalSince1970: 1))
        let second = Session(startedAt: Date(timeIntervalSince1970: 2))

        try store.save(first)
        try store.save(second)

        let history = try store.loadHistory()
        #expect(history.map(\.id) == [second.id, first.id])
    }

    @Test func emptyHistoryReadsAsEmptyArray() throws {
        let store = try makeStore()
        #expect(try store.loadHistory().isEmpty)
    }

    @Test func inProgressMarkerIsRecoverableAsAbandoned() throws {
        let store = try makeStore()
        var session = Session()
        session.status = .inProgress

        try store.markInProgress(session)
        let abandoned = try store.loadAbandonedInProgressSession()

        #expect(abandoned?.id == session.id)
        #expect(abandoned?.status == .inProgress)
    }

    @Test func noMarkerMeansNoAbandonedSession() throws {
        let store = try makeStore()
        #expect(try store.loadAbandonedInProgressSession() == nil)
    }

    // MARK: - Clear History (Blueprint §8)

    @Test func clearAllTimeEmptiesHistoryAndReportsCount() throws {
        let store = try makeStore()
        try store.save(completed(startedAt: Date(timeIntervalSince1970: 1)))
        try store.save(completed(startedAt: Date(timeIntervalSince1970: 2)))

        let removed = try store.clearHistory(.allTime, asOf: Date())

        #expect(removed == 2)
        #expect(try store.loadHistory().isEmpty)
    }

    @Test func clearOlderThanRemovesOnlyOldSessionsKeepingOrder() throws {
        let store = try makeStore()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let recentA = completed(startedAt: now.addingTimeInterval(-5 * 86_400))
        let recentB = completed(startedAt: now.addingTimeInterval(-10 * 86_400))
        let old = completed(startedAt: now.addingTimeInterval(-40 * 86_400))
        // Saved oldest-first so the store ends up most-recent-first: [recentA, recentB, old]
        try store.save(old)
        try store.save(recentB)
        try store.save(recentA)

        let removed = try store.clearHistory(.olderThan(days: 30), asOf: now)

        #expect(removed == 1)
        #expect(try store.loadHistory().map(\.id) == [recentA.id, recentB.id])
    }

    @Test func clearDoesNotDisturbTheInProgressMarker() throws {
        let store = try makeStore()
        try store.save(completed(startedAt: Date(timeIntervalSince1970: 1)))
        // markInProgress *after* save — save() itself clears any marker.
        var inProgress = Session()
        inProgress.status = .inProgress
        try store.markInProgress(inProgress)

        _ = try store.clearHistory(.allTime, asOf: Date())

        let abandoned = try store.loadAbandonedInProgressSession()
        #expect(abandoned?.id == inProgress.id)
    }

    @Test func clearOnEmptyHistoryReturnsZeroAndDoesNotThrow() throws {
        let store = try makeStore()
        #expect(try store.clearHistory(.allTime, asOf: Date()) == 0)
        #expect(try store.loadHistory().isEmpty)
    }

    @Test func clearOlderThanMatchingNothingLeavesHistoryUntouched() throws {
        let store = try makeStore()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        try store.save(completed(startedAt: now.addingTimeInterval(-2 * 86_400)))
        try store.save(completed(startedAt: now.addingTimeInterval(-1 * 86_400)))

        let removed = try store.clearHistory(.olderThan(days: 30), asOf: now)

        #expect(removed == 0)
        #expect(try store.loadHistory().count == 2)
    }

    @Test func failedClearLeavesHistoryExactlyAsItWas() throws {
        // Best-effort atomicity check: make the store's directory
        // unwritable so the `.atomic` write can't create its temp file.
        // History must be byte-for-byte unchanged and the call must throw.
        let dir = makeDir()
        let store = try JSONFileSessionStore(directory: dir)
        try store.save(completed(startedAt: Date(timeIntervalSince1970: 1)))
        try store.save(completed(startedAt: Date(timeIntervalSince1970: 2)))
        let before = try store.loadHistory().map(\.id)

        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: dir.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dir.path) }

        #expect(throws: (any Error).self) {
            try store.clearHistory(.allTime, asOf: Date())
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dir.path)
        #expect(try store.loadHistory().map(\.id) == before)
    }

    @Test func savingClearsTheInProgressMarker() throws {
        // Blueprint §8: interruption detection only ever finds a
        // *leftover* marker — once a session is properly saved
        // (Completed or Cancelled), it must stop looking abandoned.
        let store = try makeStore()
        var session = Session()
        session.status = .inProgress
        try store.markInProgress(session)

        session.status = .cancelled
        try store.save(session)

        #expect(try store.loadAbandonedInProgressSession() == nil)
    }
}
