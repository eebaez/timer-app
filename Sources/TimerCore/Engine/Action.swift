import Foundation

/// Every state-mutating input the engine accepts — Blueprint §8.
///
/// `tick` is dispatched continuously (roughly every second) by whatever
/// is driving the live clock; everything else corresponds to a single
/// candidate action or system event. The engine is pure: durations are
/// always passed in, never read from the wall clock internally, so it
/// can be tested with synthetic time instead of real waiting.
public enum Action: Equatable, Sendable {
    /// Start Session — Blueprint §8.
    case start

    /// The live clock advancing. `sessionElapsed` is the running
    /// session-level total; `activeBlockElapsed` is how long the
    /// current block has been active. Crossing the active block's
    /// baseline here is what triggers the Block Time Elapses contract.
    case tick(sessionElapsed: Duration, activeBlockElapsed: Duration)

    /// Advance to Next Block ("Next") — Blueprint §8. Advancing past
    /// Deep Dives triggers Complete Session instead of activating a
    /// next block, per the Blueprint's own note under that contract.
    case advance

    /// Skip Block ("Skip block") — Blueprint §8. Only valid while
    /// Data Flow is the active block.
    case skip

    /// Cancel Session — Blueprint §8. `confirmed: false` is the
    /// "Keep going" decline path: no state change.
    case cancel(confirmed: Bool)

    /// Interruption Detected — Blueprint §8. Dispatched once at app
    /// launch when an abandoned in-progress session is found.
    case interruptionDetected
}
