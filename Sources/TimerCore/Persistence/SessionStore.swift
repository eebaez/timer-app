import Foundation

/// Local, on-device persistence for Session History — Blueprint §7:
/// "no accounts or authentication, history does not sync across
/// devices." Also carries the abandoned-session marker used to
/// detect an Interruption at launch (Blueprint §8, §13).
public protocol SessionStore: Sendable {
    /// Persists a Completed or Cancelled session to History,
    /// most-recent-first on read. Corresponds to `SessionSaved`.
    func save(_ session: Session) throws

    /// All saved sessions, most recent first — Blueprint §10
    /// (Session History row order).
    func loadHistory() throws -> [Session]

    /// Permanently removes every saved History record matching `scope`
    /// (Blueprint §8 "Confirm Clear History"), returning the number
    /// removed.
    ///
    /// All-or-nothing: on any failure, History is left exactly as it
    /// was — never a partial delete. Never touches the in-progress
    /// marker or any live session. `now` is passed in rather than read
    /// from the wall clock so day-range scopes are testable without
    /// waiting.
    @discardableResult
    func clearHistory(_ scope: HistoryClearScope, asOf now: Date) throws -> Int

    /// Records that a session is now In Progress, so it can be
    /// recovered as abandoned if the app never reaches Completed or
    /// Cancelled for it. Overwrites any prior marker.
    func markInProgress(_ session: Session) throws

    /// Clears the in-progress marker. Called once a session reaches
    /// Completed or Cancelled through the normal flow.
    func clearInProgressMarker() throws

    /// A session left over from a prior run that never reached
    /// Completed or Cancelled — checked once at launch (Blueprint §13:
    /// "Interruption detection only runs at app launch").
    func loadAbandonedInProgressSession() throws -> Session?
}
