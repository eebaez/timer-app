import SwiftUI
import TimerCore

/// Blueprint §10 "Active session" + the Time's Up nudge.
struct ActiveSessionView: View {
    @Bindable var model: AppModel
    /// Passed by value from RootView each time `model.session`
    /// changes (every tick), rather than force-unwrapped here — see
    /// SummaryView for why that pattern crashes on the transition out.
    let session: Session

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var activeIndex: Int {
        session.blocks.firstIndex { $0.outcome == .active } ?? 0
    }

    private var activeBlock: Block { session.blocks[activeIndex] }
    private var isAlerted: Bool { activeBlock.wasAlerted }
    private var isSkippable: Bool { activeBlock.name == Block.skippableBlockName }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BLOCK \(activeIndex + 1) OF \(session.blocks.count)")
                Spacer()
                Text("SESSION \(session.elapsed.timerFormatted())")
            }
            .font(.caption2.monospaced())
            .foregroundStyle(Theme.inkSoft)
            .accessibilityElement(children: .combine)

            Text(activeBlock.name)
                .font(.title3.bold())

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(countdownText)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(isAlerted ? Theme.accent : Theme.ink)
                    .monospacedDigit()

                if isAlerted {
                    Text("TIME'S UP")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.accent)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(isAlerted ? "\(activeBlock.name), time's up, \(countdownText) over" : "\(activeBlock.name), \(countdownText) remaining")

            Text("baseline \(activeBlock.baseline.wholeMinutesLabel) · of \(Session.target.wholeMinutesLabel) budget")
                .font(.caption2.monospaced())
                .foregroundStyle(Theme.inkSoft)

            BlockProgressBar(blocks: session.blocks)
                .padding(.vertical, 2)

            Button {
                model.advance()
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .keyboardShortcut(.space, modifiers: [])
            .primaryPillStyle()
            .controlSize(.large)

            Divider()

            HStack {
                if isSkippable {
                    LinkButton(title: "Skip block") { model.skip() }
                        .font(.callout)
                }
                Spacer()
                LinkButton(title: "Cancel session") { model.requestCancel() }
                    .font(.callout)
            }
        }
        .padding(18)
        // Fixed, not a min/max range — the window-corner positioning
        // in AppModel needs to know this card's exact size in advance
        // rather than guess at it (a `minWidth...maxWidth` range left
        // that guess visibly wrong: the corner position was computed
        // for a size larger than what the card actually rendered at).
        .frame(width: 320)
        .foregroundStyle(Theme.ink)
        .background(Theme.background)
        .background {
            // The Blueprint's "highlight" nudge (§7, §11) — a single
            // steady state change, never a blink/pulse loop, and
            // never the only carrier of the alert (the "Time's up"
            // text and "+overrun" format already carry the same
            // meaning). Animated when motion is allowed, instant
            // otherwise — either way it never repeats.
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isAlerted ? Theme.accent : Color.clear, lineWidth: 2)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: isAlerted)
        }
        .sheet(isPresented: $model.showCancelConfirmation, onDismiss: {
            model.onSessionSheetDismissed()
        }) {
            CancelConfirmationView(model: model, session: session)
        }
        // Belt-and-suspenders alongside the button's own
        // `.keyboardShortcut(.space)` — see AppDelegate.swift for why
        // plain key events needed a second safeguard.
        .onKeyPress(.space) {
            model.advance()
            return .handled
        }
    }

    private var countdownText: String {
        if isAlerted {
            let spent = activeBlock.timeSpent ?? .zero
            let overrun = spent - activeBlock.baseline
            return overrun.signedFormatted()
        } else {
            let spent = activeBlock.timeSpent ?? .zero
            let remaining = activeBlock.baseline - spent
            return remaining.timerFormatted()
        }
    }
}
