import SwiftUI
import TimerCore

/// Blueprint §10 "Home".
struct HomeView: View {
    @Bindable var model: AppModel
    @State private var showHistoryPlaceholder = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 36))
                .foregroundStyle(Theme.inkSoft)

            Text("Interview Timer")
                .font(.largeTitle.bold())

            Text("Practice pacing a system design interview, solo, against a realistic clock.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: 360)
                .fixedSize(horizontal: false, vertical: true) // don't let a tight VStack truncate this

            Button {
                model.startSession()
            } label: {
                HStack(spacing: 10) {
                    Text("Start Session")
                    Image(systemName: "return")
                        .opacity(0.6)
                }
                .font(.title2.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .keyboardShortcut(.defaultAction)
            .primaryPillStyle()
            .controlSize(.large)

            LinkButton(title: "Session History") {
                showHistoryPlaceholder = true
            }

            Divider()
                .frame(maxWidth: 640)

            templatePreview

            if model.showInterruptionNotice {
                interruptionBanner
            }
        }
        .padding(40)
        .frame(minWidth: 680, minHeight: 460)
        .themedSurface()
        .sheet(isPresented: $showHistoryPlaceholder) {
            SessionHistoryView(model: model)
        }
        // Belt-and-suspenders alongside the button's own
        // `.keyboardShortcut(.defaultAction)` — see AppDelegate.swift
        // for why plain key events needed a second safeguard.
        .onKeyPress(.return) {
            model.startSession()
            return .handled
        }
    }

    /// Two columns per the design: Requirements/Core Entities/API in
    /// the left column, Data Flow/High-Level Design/Deep Dives in the
    /// right — a column-major split of the fixed six-block template,
    /// not row-major interleaving.
    private var templatePreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TEMPLATE · \(Block.defaultTemplate.count) BLOCKS · \(Session.target.wholeMinutesLabel.uppercased())")
                .font(.caption.monospaced())
                .foregroundStyle(Theme.inkSoft)

            HStack(alignment: .top, spacing: 40) {
                templateColumn(Array(Block.defaultTemplate.prefix(3)))
                templateColumn(Array(Block.defaultTemplate.suffix(3)))
            }
        }
        .frame(maxWidth: 640)
    }

    private func templateColumn(_ blocks: [Block]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(blocks, id: \.name) { block in
                HStack {
                    Text(block.name)
                    Spacer()
                    Text(block.baseline.wholeMinutesLabel)
                        .monospacedDigit()
                        .foregroundStyle(Theme.inkSoft)
                }
                .accessibilityElement(children: .combine)
                Divider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var interruptionBanner: some View {
        HStack(spacing: 10) {
            Circle().fill(Theme.accent).frame(width: 7, height: 7)
                .accessibilityHidden(true) // decorative — the text already says it
            Text("Your last session ended unexpectedly and was saved as Cancelled.")
                .font(.callout)
            Spacer()
            // Blueprint §13: if a Clear History action removed the
            // session this notice points at, keep the text but drop the
            // now-dead link.
            if model.interruptionNoticeSessionID != nil {
                Button("View") { showHistoryPlaceholder = true }
                    .buttonStyle(.plain)
                    .underline()
                    .foregroundStyle(Theme.accent)
            }
            Button {
                model.dismissInterruptionNotice()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(12)
        .frame(maxWidth: 640)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
