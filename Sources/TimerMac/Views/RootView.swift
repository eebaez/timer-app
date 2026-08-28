import SwiftUI
import TimerCore

/// Switches between Home, an in-progress session, and Summary.
struct RootView: View {
    @Bindable var model: AppModel

    var body: some View {
        Group {
            if let session = model.session {
                if session.status == .inProgress {
                    ActiveSessionView(model: model, session: session)
                } else {
                    SummaryView(model: model, session: session)
                }
            } else {
                HomeView(model: model)
            }
        }
        // Deliberately no cross-fade here. Home and the Active Session
        // card are structurally very different layouts at different
        // window sizes/positions — animating between them read as a
        // flash/glitch rather than a smooth transition, no matter how
        // well-timed the window resize itself was. A hard cut is the
        // cleaner result, not a fallback.
        .background(WindowAccessor { model.resolveHostWindow($0) })
    }
}
