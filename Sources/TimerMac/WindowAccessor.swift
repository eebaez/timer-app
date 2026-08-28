import AppKit
import SwiftUI

/// Hands the hosting `NSWindow` back to SwiftUI once it exists.
/// `AppModel` uses it to reposition the window itself — see
/// `AppModel.syncWindowPlacement`.
struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onResolve(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
