import Foundation

/// String forms for `Duration` matching Blueprint §10 exactly — shared
/// so a future iOS UI renders identically to macOS, not a re-derivation.
extension Duration {
    /// "MM:SS", minutes zero-padded to at least 2 digits. Used for the
    /// live countdown before it crosses its baseline, and for the
    /// session-elapsed header.
    public func timerFormatted() -> String {
        let totalSeconds = Int(components.seconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// "+M:SS" / "-M:SS", minutes NOT zero-padded — Blueprint §10's
    /// overrun format (`+0:45`) and the delta-vs-target format used on
    /// Summary/History/Detail.
    public func signedFormatted() -> String {
        let totalSeconds = Int(components.seconds)
        let sign = totalSeconds < 0 ? "-" : "+"
        let absSeconds = abs(totalSeconds)
        let minutes = absSeconds / 60
        let seconds = absSeconds % 60
        return String(format: "%@%d:%02d", sign, minutes, seconds)
    }

    /// "5m", "15m" — whole-minute labels for baselines/targets, as
    /// shown on Home's template preview and the active-session budget
    /// line (Blueprint §10, no "~" per the finalized 45-minute spec).
    public var wholeMinutesLabel: String {
        "\(Int(components.seconds / 60))m"
    }
}
