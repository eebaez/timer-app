import SwiftUI
import TimerCore

/// The progress bar + per-block table — shared between Summary (end
/// of a live session) and Session Detail (browsing History), since
/// both show the same breakdown of the same kind of data — Blueprint
/// §10 says as much explicitly ("same format as the corresponding
/// Summary above"). The header row (title/date + subline, alongside
/// `TotalStatView`) is each caller's own, since Summary's and
/// Detail's headers differ — but per the designs, that header row and
/// the total-time stat sit side by side in one row, not stacked.
struct SessionBreakdownView: View {
    let session: Session

    private func isDimmed(_ block: Block) -> Bool {
        block.outcome == .skipped || block.outcome == .notReached
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            BlockProgressBar(blocks: session.blocks)
            blockTable
        }
    }

    private var blockTable: some View {
        VStack(spacing: 0) {
            Divider()
            ForEach(session.blocks, id: \.name) { block in
                HStack {
                    Text(block.name)
                        .foregroundStyle(isDimmed(block) ? Theme.inkSoft : Theme.ink)
                    Spacer()
                    trailing(for: block)
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
                Divider()
            }
        }
    }

    /// Whether this block individually ran past its own baseline —
    /// purely a visual nudge (per the design, shown in orange); it
    /// never affects pass/fail, only the session-level target does.
    private func isOverBaseline(_ block: Block) -> Bool {
        guard let spent = block.timeSpent else { return false }
        return spent > block.baseline
    }

    @ViewBuilder
    private func trailing(for block: Block) -> some View {
        switch block.outcome {
        case .done:
            Text("\(block.timeSpent?.timerFormatted() ?? "00:00") · \(block.baseline.wholeMinutesLabel)")
                .monospacedDigit()
                .foregroundStyle(isOverBaseline(block) ? Theme.accent : Theme.inkSoft)
        case .active:
            // The block active when Cancel happened — "in progress",
            // per Blueprint §10, not Done/Skipped/Not Reached.
            Text("\(block.timeSpent?.timerFormatted() ?? "00:00") · in progress")
                .monospacedDigit()
                .foregroundStyle(isOverBaseline(block) ? Theme.accent : Theme.inkSoft)
        case .skipped:
            HStack(spacing: 6) {
                // Not counted as an attempt against a baseline (no
                // "· 5m" here, unlike Done/In Progress rows) — but
                // shown so the session total and this breakdown
                // always sum to the same number.
                if let spent = block.timeSpent, spent > .zero {
                    Text("\(spent.timerFormatted()) before skipping")
                        .font(.caption2)
                        .foregroundStyle(Theme.inkTertiary)
                        .monospacedDigit()
                }
                Text("SKIPPED")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay(Capsule().stroke(Theme.inkSoft))
            }
        case .notReached:
            Text("Not reached")
                .foregroundStyle(Theme.inkSoft)
        case .upcoming:
            EmptyView() // never occurs once a session has ended
        }
    }
}

/// A `COMPLETED`/`CANCELLED` badge — Blueprint §10: shown on Session
/// History rows and next to Session Detail's date, same treatment.
struct SessionStatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Text(status == .completed ? "COMPLETED" : "CANCELLED")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(Capsule().stroke(Theme.inkSoft))
    }
}

/// Blueprint §10's Summary/Detail subline — shared since Detail uses
/// "the same format as the corresponding Summary above."
func sessionSubline(for session: Session) -> String {
    guard session.status == .completed else {
        return "Ended during \(session.cancelledAtBlock ?? "") at \(session.elapsed.timerFormatted())."
    }
    let skippedDataFlow = session.blocks.contains { $0.outcome == .skipped }
    return skippedDataFlow
        ? "All six blocks carried through, one skipped by choice."
        : "All six blocks carried through."
}

/// Summary/Detail's header: title (or date+badge) and the `TOTAL TIME`
/// stat, laid out as a genuine two-column grid rather than two
/// independently-sized stacks — the title row baseline-aligns with
/// the elapsed-time digits (both large), and the subline
/// baseline-aligns with the delta (both small/secondary). `TOTAL TIME`
/// itself has no left-column counterpart, so it sits alone above the
/// grid, right-aligned to match the column below it.
struct SessionSummaryHeader<Title: View>: View {
    let session: Session
    private let title: Title

    init(session: Session, @ViewBuilder title: () -> Title) {
        self.session = session
        self.title = title()
    }

    private var delta: Duration { session.elapsed - Session.target }
    private var isOverTarget: Bool { delta.components.seconds > 0 }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("TOTAL TIME")
                .font(.caption2.monospaced())
                .foregroundStyle(Theme.inkSoft)

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 24, verticalSpacing: 6) {
                GridRow {
                    title
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(session.elapsed.timerFormatted())
                        .font(.title.bold())
                        .monospacedDigit()
                        .gridColumnAlignment(.trailing)
                }
                GridRow {
                    Text(sessionSubline(for: session))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(delta.signedFormatted()) vs. \(Session.target.wholeMinutesLabel) target")
                        .foregroundStyle(isOverTarget ? Theme.accent : Theme.inkSoft)
                        .monospacedDigit()
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
