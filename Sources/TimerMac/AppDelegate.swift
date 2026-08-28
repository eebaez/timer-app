import AppKit

/// SPM-built executables (no proper .app bundle / Info.plist yet —
/// that's Phase 6 packaging) don't reliably get NSApplication
/// activation for free when launched outside Finder. Without this,
/// the window can still accept mouse clicks but doesn't become key,
/// so keyboard shortcuts silently don't fire even though everything
/// looks normal on screen.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
