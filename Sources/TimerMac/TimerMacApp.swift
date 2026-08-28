import SwiftUI
import TimerCore

@main
struct TimerMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel(store: TimerMacApp.makeStore())

    var body: some Scene {
        WindowGroup("Interview Timer") {
            RootView(model: model)
        }
        .windowResizability(.contentSize)
        // `.contentSize` alone had a launch-time glitch: the very
        // first frame (e.g. Home with the interruption banner already
        // showing) could render before the window grew to match it,
        // clipping content top and bottom. An explicit default size —
        // generous enough for Home's tallest state — fixes the first
        // frame; `.contentSize` still governs resizing after that.
        .defaultSize(width: 700, height: 620)
    }

    private static func makeStore() -> SessionStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("InterviewTimer", isDirectory: true)
        // Application Support should always be creatable in our own
        // sandbox; if it somehow isn't, there's no reasonable UI to
        // recover into, so this fails loudly rather than silently
        // losing every session going forward.
        return try! JSONFileSessionStore(directory: directory)
    }
}
