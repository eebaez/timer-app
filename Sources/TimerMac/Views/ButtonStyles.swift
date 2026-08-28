import SwiftUI

/// The design's three recurring action styles, factored out so
/// Start Session, Next, and Keep going don't each redefine the same
/// "ink-colored pill" treatment slightly differently.
extension View {
    /// Primary action: an ink-colored pill — used by Start Session,
    /// Next, Keep going, and Done. Tint and label are both set
    /// explicitly, rather than relying on `.borderedProminent` to
    /// derive a contrasting label color from the tint — with
    /// `.tint(.primary)` that derivation didn't invert correctly in
    /// light mode, leaving near-black label text on the near-black
    /// pill, nearly unreadable. `controlActiveState` is pinned to
    /// `.active` too: macOS automatically desaturates a prominent
    /// button's tint when its window isn't key, but our label color
    /// is a fixed value that doesn't desaturate along with it —
    /// without pinning this, the window losing focus reproduces the
    /// same near-unreadable pill by a different route.
    func primaryPillStyle() -> some View {
        buttonStyle(.borderedProminent)
            .tint(Theme.ink)
            .foregroundStyle(Theme.background)
            .buttonBorderShape(.capsule)
            .environment(\.controlActiveState, .active)
    }

    /// Secondary action: a bordered pill with no fill — used by
    /// Cancel session in the confirmation dialog.
    func secondaryPillStyle() -> some View {
        buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
    }
}

/// A muted, permanently-underlined text link — Session History, Skip
/// block, Cancel session — deliberately not the system's default blue
/// link color, which the design doesn't use anywhere.
struct LinkButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).underline()
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.inkSoft)
    }
}
