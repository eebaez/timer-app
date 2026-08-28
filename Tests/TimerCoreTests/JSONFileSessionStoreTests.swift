import Foundation
import Testing
@testable import TimerCore

struct JSONFileSessionStoreTests {
    private func makeStore() throws -> JSONFileSessionStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("InterviewTimerTests-\(UUID().uuidString)")
        return try JSONFileSessionStore(directory: dir)
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
