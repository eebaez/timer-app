import SwiftUI
import TimerCore

/// Blueprint §10 "Cancel confirmation". `Keep going` is the
/// default-focused choice (§15 decision); Escape does the same thing
/// as choosing it (§11 Accessibility Behavior).
struct CancelConfirmationView: View {
    @Bindable var model: AppModel
    let session: Session

    private var activeBlockName: String {
        session.blocks.first { $0.outcome == .active }?.name ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cancel this session?")
                .font(.title3.bold())

            Text("You're \(session.elapsed.timerFormatted()) into \(activeBlockName). This session will be saved as Cancelled.")
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("Keep going") {
                    model.declineCancel()
                }
                .keyboardShortcut(.defaultAction)
                .primaryPillStyle()

                Button("Cancel session") {
                    model.confirmCancel()
                }
                .secondaryPillStyle()
            }
            .frame(maxWidth: .infinity)

            Text("esc keeps the session running")
                .font(.caption2.monospaced())
                .foregroundStyle(Theme.inkTertiary)
                .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(width: 320)
        .themedSurface()
        .onExitCommand {
            model.declineCancel()
        }
    }
}
