import SwiftUI
import TimerCore

/// Blueprint §10 "Summary — Completed" / "Summary — Cancelled" — one
/// view, since the two are the same screen with different copy/data,
/// exactly as the Blueprint frames them.
struct SummaryView: View {
    @Bindable var model: AppModel
    /// Passed by value from RootView, not read live through
    /// `model.session` — this screen describes a session that has
    /// already ended, and reading the optional directly here caused a
    /// crash: tapping Done sets `model.session = nil`, and SwiftUI
    /// re-evaluates this view's body once more before RootView swaps
    /// it out, force-unwrapping a nil.
    let session: Session

    private var isCompleted: Bool { session.status == .completed }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SessionSummaryHeader(session: session) {
                Text(isCompleted ? "Session Complete" : "Session Cancelled")
                    .font(.title.bold())
            }

            SessionBreakdownView(session: session)

            if model.saveFailed {
                saveFailureNotice
            }

            HStack {
                Spacer()
                Button("Done") { model.returnToHome() }
                    .keyboardShortcut(.defaultAction)
                    .primaryPillStyle()
            }
        }
        .padding(28)
        .frame(minWidth: 560)
        .themedSurface()
        .onKeyPress(.return) {
            model.returnToHome()
            return .handled
        }
    }

    private var saveFailureNotice: some View {
        HStack {
            Text("Couldn't save this session to History.")
            Spacer()
            Button("Retry") { model.retrySave() }
                .buttonStyle(.link)
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
