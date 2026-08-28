import SwiftUI
import TimerCore

/// Blueprint §10 "Session History". Presented as a sheet from Home;
/// selecting a row swaps in `SessionDetailView` within the same
/// sheet rather than pushing a new window.
struct SessionHistoryView: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [Session] = []
    @State private var selected: Session?

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
        .onAppear { sessions = model.loadHistory() }
        .themedSurface()
    }

    private var listView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Session History")
                    .font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .primaryPillStyle()
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
            .buttonStyle(.borderedProminent)
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
