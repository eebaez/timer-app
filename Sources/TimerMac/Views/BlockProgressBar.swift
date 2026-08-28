import SwiftUI
import TimerCore

/// Blueprint §10 "Shared: block progress bar" — appears on Active
/// session, Time's Up, Summary (Completed & Cancelled), Session
/// History (Phase 4), and Session Detail (Phase 4). Informational
/// only: not interactive, never navigates.
struct BlockProgressBar: View {
    let blocks: [Block]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(blocks, id: \.name) { block in
                Capsule()
                    .fill(color(for: block.outcome))
                    .frame(height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    private func color(for outcome: BlockOutcome) -> Color {
        switch outcome {
        case .done, .active: Theme.ink.opacity(0.75)
        case .skipped: Theme.inkSoft.opacity(0.45)
        case .upcoming, .notReached: Theme.inkSoft.opacity(0.2)
        }
    }
}
