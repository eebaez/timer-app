import SwiftUI
import TimerCore

extension HistoryClearScope: Identifiable {
    /// Stable identity so the confirmation can be driven by
    /// `.sheet(item:)`.
    public var id: String {
        switch self {
        case .allTime: return "allTime"
        case .olderThan(let days): return "olderThan-\(days)"
        }
    }
}

/// Blueprint §10 "Session History". Presented as a sheet from Home;
/// selecting a row swaps in `SessionDetailView` within the same
/// sheet rather than pushing a new window.
struct SessionHistoryView: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [Session] = []
    @State private var selected: Session?
    /// Non-nil while the Clear History confirmation is showing.
    @State private var pendingScope: HistoryClearScope?
    /// Captured once, when `pendingScope` is set — reused for both the
    /// confirmation's displayed count and the actual delete, so the two
    /// can't drift apart if the dialog is left open across a day
    /// boundary (Blueprint §13: the count is "recomputed at confirm
    /// time," not re-sampled a second time between showing it and
    /// acting on it).
    @State private var pendingScopeAsOf: Date = Date()
    /// Cached alongside `sessions` (`updateClearCounts()`) rather than
    /// recomputed on every body evaluation of `clearHistoryMenu`.
    @State private var count30 = 0
    @State private var count90 = 0

    var body: some View {
        Group {
            if let selected {
                SessionDetailView(session: selected) {
                    self.selected = nil // back to the list, not the whole sheet
                }
            } else {
                listView
            }
        }
        // No fixed frame here — List and Detail have genuinely
        // different natural heights (Detail's six-row table is
        // roughly constant regardless of session; List needs room to
        // scroll). A fixed size on the shared container meant
        // whichever screen was shorter always left dead space. Each
        // screen now sizes to its own content, same as the main
        // window already does between Home/Active Session/Summary.
        .onAppear {
            reloadSessions()
            model.acknowledgeClearFailure() // don't greet a return visit with a stale failure
        }
        .themedSurface()
    }

    private func reloadSessions() {
        sessions = model.loadHistory()
        updateClearCounts()
    }

    private func updateClearCounts() {
        let now = Date()
        count30 = sessions.matching(.olderThan(days: 30), asOf: now).count
        count90 = sessions.matching(.olderThan(days: 90), asOf: now).count
    }

    private var listView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Session History")
                    .font(.title2.bold())
                Spacer()
                if !sessions.isEmpty {
                    clearHistoryMenu
                }
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .primaryPillStyle()
            }

            if model.clearFailed {
                clearFailureNotice
            }

            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(sessions, id: \.id) { session in
                            Button {
                                selected = session
                            } label: {
                                row(for: session)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(accessibilityLabel(for: session))
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 420, maxHeight: 560)
        .sheet(item: $pendingScope) { scope in
            ClearHistoryConfirmationView(
                scope: scope,
                // Same instant captured when the scope was chosen, not
                // re-sampled here — see `pendingScopeAsOf` (Blueprint §13).
                count: sessions.matching(scope, asOf: pendingScopeAsOf).count,
                onKeep: { pendingScope = nil },
                onClear: {
                    model.clearHistory(scope, asOf: pendingScopeAsOf)
                    pendingScope = nil
                    reloadSessions() // reflect the delete; empty => emptyState, menu hides
                }
            )
        }
    }

    /// Blueprint §10: grouped with `Done` at the trailing edge, hidden
    /// when the list is empty. Opens a menu rather than acting
    /// immediately, so it needs no spatial separation from `Done`.
    private var clearHistoryMenu: some View {
        Menu {
            // A day-range scope matching zero sessions is omitted, not
            // shown disabled — never offer a confirmed no-op (Diff §7).
            if count30 > 0 {
                scopeButton("Older than 30 days", scope: .olderThan(days: 30), count: count30)
            }
            if count90 > 0 {
                scopeButton("Older than 90 days", scope: .olderThan(days: 90), count: count90)
            }
            // Divider only when a day-range scope is present above it.
            if count30 > 0 || count90 > 0 {
                Divider()
            }
            scopeButton("All Time", scope: .allTime, count: sessions.count)
        } label: {
            Text("Clear History")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func scopeButton(_ title: String, scope: HistoryClearScope, count: Int) -> some View {
        Button {
            pendingScopeAsOf = Date()
            pendingScope = scope
        } label: {
            Text(title)
        }
        .badge(count)
        .accessibilityLabel("\(title), \(count) \(clearHistorySessionNoun(count))")
    }

    /// Blueprint §13: a failed clear leaves History exactly as it was
    /// and surfaces this retriable notice — same pattern as Summary's
    /// save-failure notice.
    private var clearFailureNotice: some View {
        HStack {
            Text("Couldn't clear history.")
                .foregroundStyle(Theme.accent)
            Spacer()
            Button("Retry") {
                model.retryClear()
                reloadSessions()
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding(12)
        .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.accent.opacity(0.35))
        )
    }

    private func row(for session: Session) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dateLabel(session))
                SessionStatusBadge(status: session.status)
                Spacer()
                Text(session.elapsed.timerFormatted())
                    .monospacedDigit()
                Text("(\(rowDelta(session).signedFormatted()))")
                    .monospacedDigit()
                    .foregroundStyle(rowDelta(session) > .zero ? Theme.accent : Theme.inkSoft)
            }
            BlockProgressBar(blocks: session.blocks)
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("No sessions yet. Start your first practice session from Home.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: 320)
            Button("Start Session") {
                dismiss()
                model.startSession()
            }
            .primaryPillStyle()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func dateLabel(_ session: Session) -> String {
        session.startedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }

    private func rowDelta(_ session: Session) -> Duration {
        session.elapsed - Session.target
    }

    /// A clean sentence for VoiceOver instead of the row's scattered
    /// text fragments read one after another.
    private func accessibilityLabel(for session: Session) -> String {
        let status = session.status == .completed ? "Completed" : "Cancelled"
        return "\(dateLabel(session)), \(status), \(session.elapsed.timerFormatted()), \(rowDelta(session).signedFormatted()) versus target"
    }
}
