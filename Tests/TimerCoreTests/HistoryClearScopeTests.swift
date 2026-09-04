import Foundation
import Testing
@testable import TimerCore

struct HistoryClearScopeTests {
    /// A fixed reference "now" so the day-range math is deterministic.
    private let now = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14 22:13:20 UTC

    private func session(daysBeforeNow days: Double) -> Session {
        Session(startedAt: now.addingTimeInterval(-days * 86_400))
    }

    @Test func allTimeMatchesEverything() {
        let history = [session(daysBeforeNow: 0), session(daysBeforeNow: 5), session(daysBeforeNow: 500)]
        #expect(history.matching(.allTime, asOf: now).count == history.count)
    }

    @Test func allTimeOnEmptyHistoryMatchesNothing() {
        let history: [Session] = []
        #expect(history.matching(.allTime, asOf: now).isEmpty)
    }

    @Test func olderThanRemovesOnlyOlderSessions() {
        let recent = session(daysBeforeNow: 29)
        let old = session(daysBeforeNow: 31)
        let history = [recent, old]

        let matched = history.matching(.olderThan(days: 30), asOf: now)

        #expect(matched.map(\.id) == [old.id])
    }

    @Test func boundarySessionIsKept() {
        // Exactly 30 calendar days before `now` — "from the last 30 days
        // are kept", so this must NOT match.
        let onBoundary = Session(
            startedAt: Calendar.current.date(byAdding: .day, value: -30, to: now)!
        )
        let history = [onBoundary]

        #expect(history.matching(.olderThan(days: 30), asOf: now).isEmpty)
    }

    @Test func ninetyDayScopeIsSubsetOfThirtyDayScope() {
        let history = (0..<10).map { session(daysBeforeNow: Double($0) * 20) } // 0,20,...,180 days old

        let in30 = Set(history.matching(.olderThan(days: 30), asOf: now).map(\.id))
        let in90 = Set(history.matching(.olderThan(days: 90), asOf: now).map(\.id))

        #expect(in90.isSubset(of: in30))
        #expect(in90.count < in30.count)
    }

    @Test func matchedOrderFollowsInputOrder() {
        let a = session(daysBeforeNow: 200)
        let b = session(daysBeforeNow: 150)
        let c = session(daysBeforeNow: 100)
        let history = [a, b, c] // caller keeps most-recent-first; predicate must not reorder

        #expect(history.matching(.olderThan(days: 30), asOf: now).map(\.id) == [a.id, b.id, c.id])
    }

    @Test func dayRangeMatchingNothingReturnsEmpty() {
        let history = [session(daysBeforeNow: 1), session(daysBeforeNow: 10)]
        #expect(history.matching(.olderThan(days: 30), asOf: now).isEmpty)
    }
}
