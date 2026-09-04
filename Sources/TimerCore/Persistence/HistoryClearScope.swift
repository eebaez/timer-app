import Foundation

/// The three scopes a Clear History action can target — Blueprint §8.
///
/// A retention/prune model, not a recency wipe: `.olderThan` removes
/// sessions *older* than the threshold and keeps recent ones. The
/// trigger for this feature is accumulation, not privacy — a candidate
/// practicing over weeks wants to drop old throwaway sessions while
/// keeping recent history for pacing trends.
public enum HistoryClearScope: Equatable, Sendable {
    /// Every saved session.
    case allTime
    /// Every saved session whose `startedAt` is older than `days` days.
    case olderThan(days: Int)
}

extension Array where Element == Session {
    /// The sessions this scope would remove, evaluated against `now`.
    ///
    /// `.olderThan(N)` matches a session whose `startedAt` falls strictly
    /// before the calendar point N days before `now` — a session exactly
    /// on the boundary is kept ("Sessions from the last N days are
    /// kept", Blueprint §10). Calendar arithmetic, so "N days" tracks
    /// wall-clock days across DST rather than fixed 86,400s intervals.
    public func matching(_ scope: HistoryClearScope, asOf now: Date = Date()) -> [Session] {
        switch scope {
        case .allTime:
            return self
        case .olderThan(let days):
            guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) else {
                return []
            }
            return filter { $0.startedAt < cutoff }
        }
    }
}
