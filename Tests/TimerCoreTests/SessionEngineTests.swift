import Testing
@testable import TimerCore

/// One group per Behavioral Contract — Blueprint §8.
struct SessionEngineTests {

    // MARK: - Start Session

    @Test func startMovesToInProgressAndActivatesRequirements() {
        let (session, events) = SessionEngine.reduce(Session(), .start)

        #expect(session.status == .inProgress)
        #expect(session.blocks[0].outcome == .active)
        #expect(session.blocks.dropFirst().allSatisfy { $0.outcome == .upcoming })
        #expect(events == [.sessionStarted, .blockActivated(block: "Requirements")])
    }

    @Test func startIsANoOpIfAlreadyInProgress() {
        let inProgress = SessionEngine.reduce(Session(), .start).0
        let (session, events) = SessionEngine.reduce(inProgress, .start)

        #expect(session == inProgress)
        #expect(events.isEmpty)
    }

    // MARK: - Block Time Elapses (via tick)

    @Test func tickPastBaselineFiresBlockTimeElapsedExactlyOnce() {
        var session = SessionEngine.reduce(Session(), .start).0

        // Requirements baseline is 5m. Cross it.
        let (afterFirst, firstEvents) = SessionEngine.reduce(
            session, .tick(sessionElapsed: .seconds(301), activeBlockElapsed: .seconds(301))
        )
        #expect(firstEvents == [.blockTimeElapsed(block: "Requirements")])
        #expect(afterFirst.blocks[0].wasAlerted)
        session = afterFirst

        // A later tick still past baseline must not re-fire it.
        let (afterSecond, secondEvents) = SessionEngine.reduce(
            session, .tick(sessionElapsed: .seconds(310), activeBlockElapsed: .seconds(310))
        )
        #expect(secondEvents.isEmpty)
        #expect(afterSecond.blocks[0].timeSpent == .seconds(310))
    }

    @Test func tickBelowBaselineDoesNotFireAlert() {
        let session = SessionEngine.reduce(Session(), .start).0
        let (next, events) = SessionEngine.reduce(
            session, .tick(sessionElapsed: .seconds(60), activeBlockElapsed: .seconds(60))
        )
        #expect(events.isEmpty)
        #expect(next.blocks[0].wasAlerted == false)
        #expect(next.blocks[0].timeSpent == .seconds(60))
    }

    // MARK: - Advance to Next Block

    @Test func advanceMarksCurrentDoneAndActivatesNext() {
        var session = SessionEngine.reduce(Session(), .start).0
        session = SessionEngine.reduce(
            session, .tick(sessionElapsed: .seconds(200), activeBlockElapsed: .seconds(200))
        ).0

        let (next, events) = SessionEngine.reduce(session, .advance)

        #expect(next.blocks[0].outcome == .done)
        #expect(next.blocks[0].timeSpent == .seconds(200))
        #expect(next.blocks[1].outcome == .active)
        #expect(events == [
            .blockAdvanced(fromBlock: "Requirements", toBlock: "Core Entities", timeSpent: .seconds(200)),
            .blockActivated(block: "Core Entities"),
        ])
    }

    @Test func advanceHasNoMinimumTime() {
        // Blueprint §7/§15: no minimum time enforced before Advance.
        let session = SessionEngine.reduce(Session(), .start).0
        let (next, events) = SessionEngine.reduce(session, .advance)

        #expect(next.blocks[0].outcome == .done)
        #expect(next.blocks[0].timeSpent == nil) // never ticked, not "ticked to zero"
        #expect(events.first == .blockAdvanced(fromBlock: "Requirements", toBlock: "Core Entities", timeSpent: .zero))
    }

    @Test func advanceIsANoOpWhenNotInProgress() {
        let notStarted = Session()
        let (session, events) = SessionEngine.reduce(notStarted, .advance)
        #expect(session == notStarted)
        #expect(events.isEmpty)
    }

    // MARK: - Skip Block (Data Flow only)

    @Test func skipMarksDataFlowSkippedAndActivatesHighLevelDesign() {
        var session = SessionEngine.reduce(Session(), .start).0
        for _ in 0..<3 { session = SessionEngine.reduce(session, .advance).0 } // through to Data Flow
        #expect(session.blocks[3].name == "Data Flow")
        #expect(session.blocks[3].outcome == .active)

        let (next, events) = SessionEngine.reduce(session, .skip)

        #expect(next.blocks[3].outcome == .skipped)
        #expect(next.blocks[3].timeSpent == nil) // never ticked before skipping
        #expect(next.blocks[4].outcome == .active)
        #expect(events == [.blockSkipped(block: "Data Flow"), .blockActivated(block: "High-Level Design")])
    }

    @Test func skipPreservesTimeSpentBeforeTheSkip() {
        // A session's total and its per-block breakdown must always
        // reconcile — a skip discards the block as an "attempt"
        // (Blueprint §8), but not the seconds themselves.
        var session = SessionEngine.reduce(Session(), .start).0
        for _ in 0..<3 { session = SessionEngine.reduce(session, .advance).0 } // through to Data Flow
        session = SessionEngine.reduce(
            session, .tick(sessionElapsed: .seconds(900), activeBlockElapsed: .seconds(7))
        ).0

        let (next, _) = SessionEngine.reduce(session, .skip)

        #expect(next.blocks[3].outcome == .skipped)
        #expect(next.blocks[3].timeSpent == .seconds(7))
    }

    @Test func skipIsANoOpOnAnyOtherBlock() {
        let session = SessionEngine.reduce(Session(), .start).0 // Requirements is active
        let (next, events) = SessionEngine.reduce(session, .skip)
        #expect(next == session)
        #expect(events.isEmpty)
    }

    // MARK: - Complete Session

    @Test func advancingPastDeepDivesCompletesTheSession() {
        var session = SessionEngine.reduce(Session(), .start).0
        for _ in 0..<5 { session = SessionEngine.reduce(session, .advance).0 } // through to Deep Dives
        #expect(session.blocks[5].name == "Deep Dives")
        #expect(session.blocks[5].outcome == .active)

        session = SessionEngine.reduce(
            session, .tick(sessionElapsed: .seconds(2400), activeBlockElapsed: .seconds(400))
        ).0
        let (next, events) = SessionEngine.reduce(session, .advance)

        #expect(next.status == .completed)
        #expect(next.blocks[5].outcome == .done)
        #expect(events == [
            .sessionCompleted(totalElapsed: .seconds(2400)),
            .sessionSaved(session: next),
        ])
    }

    // MARK: - Cancel Session

    @Test func cancelConfirmedEndsSessionAndMarksUpcomingNotReached() {
        var session = SessionEngine.reduce(Session(), .start).0
        session = SessionEngine.reduce(session, .advance).0 // Requirements done, Core Entities active
        session = SessionEngine.reduce(
            session, .tick(sessionElapsed: .seconds(500), activeBlockElapsed: .seconds(100))
        ).0

        let (next, events) = SessionEngine.reduce(session, .cancel(confirmed: true))

        #expect(next.status == .cancelled)
        #expect(next.wasInterrupted == false)
        #expect(next.cancelledAtBlock == "Core Entities")
        #expect(next.blocks[0].outcome == .done) // already-finished blocks are untouched
        #expect(next.blocks[1].outcome == .active) // "in progress" is represented as still-active
        #expect(next.blocks[2...].allSatisfy { $0.outcome == .notReached })
        #expect(events == [
            .sessionCancelled(atBlock: "Core Entities", interrupted: false),
            .sessionSaved(session: next),
        ])
    }

    @Test func cancelDeclinedLeavesStateUnchanged() {
        let session = SessionEngine.reduce(Session(), .start).0
        let (next, events) = SessionEngine.reduce(session, .cancel(confirmed: false))

        #expect(next == session)
        #expect(events.isEmpty)
    }

    @Test func cancelIsANoOpWhenNotInProgress() {
        let notStarted = Session()
        let (session, events) = SessionEngine.reduce(notStarted, .cancel(confirmed: true))
        #expect(session == notStarted)
        #expect(events.isEmpty)
    }

    // MARK: - Interruption Detected

    @Test func interruptionDetectedBehavesLikeConfirmedCancelButMarkedInterrupted() {
        let session = SessionEngine.reduce(Session(), .start).0
        let (next, events) = SessionEngine.reduce(session, .interruptionDetected)

        #expect(next.status == .cancelled)
        #expect(next.wasInterrupted == true)
        #expect(events == [
            .sessionCancelled(atBlock: "Requirements", interrupted: true),
            .sessionSaved(session: next),
        ])
    }
}
