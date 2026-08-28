import SwiftUI
import TimerCore

/// Blueprint §10 "Session Detail" — same breakdown as Summary, for a
/// past session read back out of History. `Done` is the same action
/// and copy as Summary's, per the Blueprint's explicit decision on
/// that (§15): consistent whether the candidate just finished a
/// session or is revisiting one.
struct SessionDetailView: View {
    let session: Session
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SessionSummaryHeader(session: session) {
                HStack(spacing: 10) {
                    Text(dateTimeLabel)
                        .font(.title.bold())
                    SessionStatusBadge(status: session.status)
                }
            }

            SessionBreakdownView(session: session)

            HStack {
                Spacer()
                Button("Done", action: onDone)
                    .keyboardShortcut(.defaultAction)
                    .primaryPillStyle()
            }
        }
        .padding(28)
        // Same bounded envelope as History's list screen
        // (`SessionHistoryView.listView`) — sizes to its own content,
        // rather than stretching to fill whatever the host window
        // happens to be, which made the sheet's size (and therefore
        // this screen's proportions) depend on the main window's
        // current size instead of being self-consistent.
        // `alignment: .topLeading` pins content to the top for the
        // rare case where it's shorter than `minHeight`.
        .frame(minWidth: 560, minHeight: 420, maxHeight: 560, alignment: .topLeading)
        .onKeyPress(.return) {
            onDone()
            return .handled
        }
    }

    private var dateTimeLabel: String {
        session.startedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}
