import Foundation

/// The entire behavioral surface of Blueprint §8 as one pure function.
/// Each Behavioral Contract in the Blueprint is one case here.
///
/// Invalid actions for the current state (e.g. `skip` when Data Flow
/// isn't active) are no-ops — they return the session unchanged with
/// no events, rather than trapping. The UI layer is responsible for
/// only presenting valid actions in the first place (Blueprint §7:
/// Skip only ever shown while Data Flow is active, etc.) — this is a
/// defensive guard, not a validated user-facing error path.
public enum SessionEngine {
    public static func reduce(_ session: Session, _ action: Action) -> (Session, [Event]) {
        switch action {
        case .start:
            return start(session)
        case .tick(let sessionElapsed, let activeBlockElapsed):
            return tick(session, sessionElapsed: sessionElapsed, activeBlockElapsed: activeBlockElapsed)
        case .advance:
            return advance(session)
        case .skip:
            return skip(session)
        case .cancel(let confirmed):
            return cancel(session, confirmed: confirmed)
        case .interruptionDetected:
            return interruptionDetected(session)
        }
    }

    // MARK: - Start Session

    private static func start(_ session: Session) -> (Session, [Event]) {
        guard session.status == .notStarted else { return (session, []) }

        var next = session
        next.status = .inProgress
        next.elapsed = .zero

        guard let firstName = next.blocks.first?.name else { return (next, []) }
        next.blocks[0].outcome = .active

        return (next, [.sessionStarted, .blockActivated(block: firstName)])
    }

    // MARK: - Block Time Elapses (via tick)

    private static func tick(
        _ session: Session,
        sessionElapsed: Duration,
        activeBlockElapsed: Duration
    ) -> (Session, [Event]) {
        guard session.status == .inProgress,
              let activeIndex = session.blocks.firstIndex(where: { $0.outcome == .active })
        else { return (session, []) }

        var next = session
        next.elapsed = sessionElapsed
        next.blocks[activeIndex].timeSpent = activeBlockElapsed

        var events: [Event] = []
        let active = next.blocks[activeIndex]
        if !active.wasAlerted, activeBlockElapsed >= active.baseline {
            next.blocks[activeIndex].wasAlerted = true
            events.append(.blockTimeElapsed(block: active.name))
        }

        return (next, events)
    }

    // MARK: - Advance to Next Block / Complete Session

    private static func advance(_ session: Session) -> (Session, [Event]) {
        guard session.status == .inProgress,
              let activeIndex = session.blocks.firstIndex(where: { $0.outcome == .active })
        else { return (session, []) }

        var next = session
        let finishedBlock = next.blocks[activeIndex]
        next.blocks[activeIndex].outcome = .done

        let isLastBlock = activeIndex == next.blocks.count - 1
        if isLastBlock {
            next.status = .completed
            return (next, [.sessionCompleted(totalElapsed: next.elapsed), .sessionSaved(session: next)])
        }

        let nextIndex = activeIndex + 1
        next.blocks[nextIndex].outcome = .active
        let toName = next.blocks[nextIndex].name

        return (next, [
            .blockAdvanced(fromBlock: finishedBlock.name, toBlock: toName, timeSpent: finishedBlock.timeSpent ?? .zero),
            .blockActivated(block: toName),
        ])
    }

    // MARK: - Skip Block (Data Flow only)

    private static func skip(_ session: Session) -> (Session, [Event]) {
        guard session.status == .inProgress,
              let activeIndex = session.blocks.firstIndex(where: { $0.outcome == .active }),
              session.blocks[activeIndex].name == Block.skippableBlockName,
              activeIndex + 1 < session.blocks.count
        else { return (session, []) }

        var next = session
        let skipped = next.blocks[activeIndex]
        next.blocks[activeIndex].outcome = .skipped
        // `timeSpent` is kept, not cleared: it's not counted as an
        // attempt against the block's baseline (Skipped ≠ Done), but
        // whatever elapsed before the skip must stay visible so a
        // session's total and its per-block breakdown always
        // reconcile — Blueprint §8, §15.

        let nextIndex = activeIndex + 1
        next.blocks[nextIndex].outcome = .active
        let toName = next.blocks[nextIndex].name

        return (next, [.blockSkipped(block: skipped.name), .blockActivated(block: toName)])
    }

    // MARK: - Cancel Session

    private static func cancel(_ session: Session, confirmed: Bool) -> (Session, [Event]) {
        guard confirmed else { return (session, []) } // "Keep going" — no state change

        guard session.status == .inProgress else { return (session, []) }

        return finishAsCancelled(session, interrupted: false)
    }

    // MARK: - Interruption Detected

    private static func interruptionDetected(_ session: Session) -> (Session, [Event]) {
        guard session.status == .inProgress else { return (session, []) }
        return finishAsCancelled(session, interrupted: true)
    }

    // MARK: - Shared Cancel / Interruption finish

    private static func finishAsCancelled(_ session: Session, interrupted: Bool) -> (Session, [Event]) {
        var next = session
        next.status = .cancelled
        next.wasInterrupted = interrupted

        let activeName = next.blocks.first { $0.outcome == .active }?.name
        next.cancelledAtBlock = activeName

        for index in next.blocks.indices where next.blocks[index].outcome == .upcoming {
            next.blocks[index].outcome = .notReached
        }
        // The active block deliberately stays `.active` — that's what
        // "in progress" means in a Cancelled session's record, per
        // Blueprint §10 Copy ("{Block Name} · {time spent} · in progress").

        return (next, [
            .sessionCancelled(atBlock: activeName, interrupted: interrupted),
            .sessionSaved(session: next),
        ])
    }
}
