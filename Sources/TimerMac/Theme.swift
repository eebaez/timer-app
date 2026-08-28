import AppKit
import SwiftUI

/// The design's exact palette, sampled directly from the
/// high-fidelity mockups (`docs/artifacts/designs`) — not left to system
/// defaults, which don't match: macOS's standard dark window
/// background and secondary-label gray are both visibly different
/// hues from what the designs actually use.
enum Theme {
    static let background = adaptive(light: "#faf9f6", dark: "#1b2027")
    static let ink = adaptive(light: "#1f2933", dark: "#e7eaee")
    static let inkSoft = adaptive(light: "#5b6774", dark: "#96a2ad")
    static let inkTertiary = adaptive(light: "#8c959e", dark: "#6f7a85")
    static let line = adaptive(light: "#e6e2da", dark: "#2b333c")
    static let accent = adaptive(light: "#b8500f", dark: "#e2853f")

    private static func adaptive(light: String, dark: String) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

extension View {
    /// Applies the design's background + default text color to a
    /// top-level screen. Each screen (including sheet content, which
    /// doesn't inherit from the presenting view) needs this
    /// individually — SwiftUI sheets are a separate presentation
    /// context, not a child of the window's view hierarchy.
    func themedSurface() -> some View {
        foregroundStyle(Theme.ink)
            .background(Theme.background)
    }
}

private extension NSColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
