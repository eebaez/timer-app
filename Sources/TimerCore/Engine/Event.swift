import Foundation

/// The 8 domain events — Blueprint §9, verbatim.
public enum Event: Equatable, Sendable {
    case sessionStarted
    case blockActivated(block: String)
    case blockTimeElapsed(block: String)
    case blockAdvanced(fromBlock: String, toBlock: String, timeSpent: Duration)
    case blockSkipped(block: String)
    case sessionCompleted(totalElapsed: Duration)
    case sessionCancelled(atBlock: String?, interrupted: Bool)
    case sessionSaved(session: Session)
}
