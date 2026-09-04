import Foundation

/// The 9 domain events — Blueprint §9, verbatim.
public enum Event: Equatable, Sendable {
    case sessionStarted
    case blockActivated(block: String)
    case blockTimeElapsed(block: String)
    case blockAdvanced(fromBlock: String, toBlock: String, timeSpent: Duration)
    case blockSkipped(block: String)
    case sessionCompleted(totalElapsed: Duration)
    case sessionCancelled(atBlock: String?, interrupted: Bool)
    case sessionSaved(session: Session)

    /// A Clear History action completed. Not produced by
    /// `SessionEngine.reduce` — clearing acts on the History
    /// *collection*, not a `Session`'s state machine — it is
    /// constructed by the app layer and routed through the same
    /// side-effect sink as the rest.
    case historyCleared(scope: HistoryClearScope, sessionsRemoved: Int)
}
