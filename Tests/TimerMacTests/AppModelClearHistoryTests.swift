import Foundation
import Testing
@testable import TimerCore
@testable import TimerMac

@MainActor
struct AppModelClearHistoryTests {
    private func completed(startedAt: Date) -> Session {
        var s = Session(startedAt: startedAt)
        s.status = .completed
        return s
    }

    private func oldAndRecentHistory(now: Date = Date()) -> [Session] {
        [
            completed(startedAt: now.addingTimeInterval(-2 * 86_400)),   // recent
            completed(startedAt: now.addingTimeInterval(-40 * 86_400)),  // old
            completed(startedAt: now.addingTimeInterval(-120 * 86_400)), // older
        ]
    }

    @Test func clearAllTimeEmptiesHistoryAndLeavesNoFailure() {
        let store = FakeSessionStore(history: oldAndRecentHistory())
        let model = AppModel(store: store)

        model.clearHistory(.allTime)

        #expect(store.history.isEmpty)
        #expect(model.clearFailed == false)
        #expect(model.loadHistory().isEmpty)
    }

    @Test func clearOlderThanKeepsRecentSessions() {
        let now = Date()
        let store = FakeSessionStore(history: oldAndRecentHistory(now: now))
        let model = AppModel(store: store)

        model.clearHistory(.olderThan(days: 30))

        #expect(store.history.count == 1)
        #expect(store.history.first?.startedAt == now.addingTimeInterval(-2 * 86_400))
        #expect(store.lastClearScope == .olderThan(days: 30))
    }

    @Test func failedClearSurfacesNoticeAndLeavesHistoryIntact() {
        let store = FakeSessionStore(history: oldAndRecentHistory())
        store.failNextClear = true
        let model = AppModel(store: store)

        model.clearHistory(.allTime)

        #expect(model.clearFailed == true)
        #expect(store.history.count == 3) // untouched — all-or-nothing
    }

    @Test func retryReplaysTheFailedScopeAndClearsTheNotice() {
        let store = FakeSessionStore(history: oldAndRecentHistory())
        store.failNextClear = true
        let model = AppModel(store: store)

        model.clearHistory(.olderThan(days: 90)) // fails
        #expect(model.clearFailed == true)

        model.retryClear() // succeeds this time

        #expect(model.clearFailed == false)
        #expect(store.lastClearScope == .olderThan(days: 90))
        #expect(store.history.count == 2) // the one >120d session removed
    }

    @Test func retryIsANoOpWhenNothingFailed() {
        let store = FakeSessionStore(history: oldAndRecentHistory())
        let model = AppModel(store: store)

        model.retryClear()

        #expect(store.clearCallCount == 0)
    }

    @Test func rapidDoubleConfirmClearsOnce() {
        let store = FakeSessionStore(history: oldAndRecentHistory())
        let model = AppModel(store: store)

        model.clearHistory(.allTime)
        model.clearHistory(.allTime) // within the debounce window

        #expect(store.clearCallCount == 1)
    }

    @Test func clearingTheLinkedSessionDropsTheInterruptionViewLink() {
        var abandoned = Session()
        abandoned.status = .inProgress
        let store = FakeSessionStore(abandoned: abandoned)
        let model = AppModel(store: store)
        // init saved the abandoned session as Cancelled and linked the notice
        #expect(model.interruptionNoticeSessionID == abandoned.id)

        model.clearHistory(.allTime)

        #expect(model.interruptionNoticeSessionID == nil)
    }

    @Test func clearingAroundTheLinkedSessionKeepsTheViewLink() {
        var abandoned = Session() // startedAt ~ now
        abandoned.status = .inProgress
        let store = FakeSessionStore(abandoned: abandoned)
        let model = AppModel(store: store)
        #expect(model.interruptionNoticeSessionID == abandoned.id)

        model.clearHistory(.olderThan(days: 30)) // doesn't cover a fresh session

        #expect(model.interruptionNoticeSessionID == abandoned.id)
    }

    @Test func dismissingTheInterruptionNoticeClearsItsLink() {
        var abandoned = Session()
        abandoned.status = .inProgress
        let store = FakeSessionStore(abandoned: abandoned)
        let model = AppModel(store: store)

        model.dismissInterruptionNotice()

        #expect(model.interruptionNoticeSessionID == nil)
        #expect(model.showInterruptionNotice == false)
    }
}
