import SwiftUI
import TimerCore

/// "1 session" / "5 sessions" — the shared plural rule for Clear
/// History copy, used here and by `SessionHistoryView`'s menu so the
/// two don't drift independently.
func clearHistorySessionNoun(_ count: Int) -> String {
    count == 1 ? "session" : "sessions"
}

/// Blueprint §10 "Clear History confirmation". Same defensive pattern
/// as `CancelConfirmationView`: `Keep History` is the default-focused,
/// non-destructive choice; Escape does the same thing as choosing it
/// (Blueprint §11). The named count + "can't be undone" wording is the
/// safeguard — no extra typing step, even for All Time (Diff §0).
struct ClearHistoryConfirmationView: View {
    let scope: HistoryClearScope
    /// Sessions the chosen scope will remove — recomputed when this
    /// confirmation opens, not cached from when the menu opened.
    let count: Int
    let onKeep: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clear \(count) \(clearHistorySessionNoun(count))?")
                .font(.title3.bold())

            Text(bodyText)
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Keep History") { onKeep() }
                    .keyboardShortcut(.defaultAction)
                    .primaryPillStyle()

                Button("Clear History") { onClear() }
                    .secondaryPillStyle()
            }
            .frame(maxWidth: .infinity)

            Text("esc keeps your history")
                .font(.caption2.monospaced())
                .foregroundStyle(Theme.inkTertiary)
                .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(width: 360)
        .themedSurface()
        .onExitCommand { onKeep() }
    }

    private var bodyText: String {
        switch scope {
        case .allTime:
            return "This permanently deletes your entire session history — \(count) \(clearHistorySessionNoun(count)). This can't be undone."
        case .olderThan(let days):
            return "This permanently deletes \(count) \(clearHistorySessionNoun(count)) older than \(days) days. Sessions from the last \(days) days are kept. This can't be undone."
        }
    }
}
