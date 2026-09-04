import AppKit
import Foundation
import Observation
import os
import SwiftUI
import TimerCore

/// Drives the live clock and translates candidate actions into
/// `SessionEngine` dispatches. Views read `session`/`showInterruptionNotice`/
/// `showCancelConfirmation` and call the methods below — nothing in
/// SwiftUI touches `SessionEngine` directly.
@MainActor
@Observable
final class AppModel {
    private(set) var session: Session?
    var showInterruptionNotice = false
    var showCancelConfirmation = false
    /// Blueprint §8/§13: `SessionSaved` failing never blocks or hides
    /// the Summary screen — it surfaces this instead.
    private(set) var saveFailed = false
    /// Blueprint §13: a failed Clear History leaves History exactly as
    /// it was and surfaces this retriable inline notice on Session
    /// History — never a partial delete, never a silent failure.
    /// Always in lockstep with `pendingClearScope`, so it's derived
    /// rather than tracked separately.
    var clearFailed: Bool { pendingClearScope != nil }
    /// The saved session behind Home's one-time interruption notice
    /// (Blueprint §10). Nil once there's no live notice, its linked
    /// session was never actually saved, or the session has since been
    /// cleared — the notice then drops its `View` link (Blueprint §13).
    private(set) var interruptionNoticeSessionID: UUID?

    private let store: SessionStore
    private var ticker: Timer?
    private var sessionStartDate: Date?
    private var blockStartDate: Date?
    private var lastActionAt = Date.distantPast
    /// Separate from `lastActionAt`: Clear History's debounce shouldn't
    /// interfere with session-lifecycle actions (Start/Next/Skip) on a
    /// different screen — e.g. confirming a clear that empties History
    /// shouldn't be able to swallow an immediately following tap on the
    /// empty state's own Start Session button.
    private var lastClearActionAt = Date.distantPast
    private var pendingSave: Session?
    private var pendingClearScope: HistoryClearScope?
    /// `startedAt` of the session behind `interruptionNoticeSessionID`,
    /// kept alongside it so a clear can check locally whether that
    /// session was just removed without re-reading History from disk.
    private var interruptionNoticeSessionStartedAt: Date?
    private weak var hostWindow: NSWindow?
    private var documentFrame: NSRect?

    private static let log = Logger(subsystem: "com.eebaez.interviewtimer", category: "history")

    init(store: SessionStore) {
        self.store = store
        checkForAbandonedSession()
    }

    // MARK: - Candidate actions

    func startSession() {
        guard debounceOK() else { return }
        let (next, events) = SessionEngine.reduce(Session(), .start)
        session = next
        sessionStartDate = Date()
        blockStartDate = Date()
        try? store.markInProgress(next)
        handle(events)
        startTicker()
        syncWindowPlacement()
    }

    func advance() {
        guard debounceOK(), let current = session else { return }
        let (next, events) = SessionEngine.reduce(current, .advance)
        session = next
        if next.status == .inProgress {
            blockStartDate = Date() // a new block just became active
        } else {
            stopTicker()
            syncWindowPlacement()
        }
        handle(events)
    }

    func skip() {
        guard debounceOK(), let current = session else { return }
        let (next, events) = SessionEngine.reduce(current, .skip)
        session = next
        blockStartDate = Date()
        handle(events)
    }

    /// Opens the confirmation — not itself debounced, since it doesn't
    /// mutate session state.
    func requestCancel() {
        showCancelConfirmation = true
    }

    func confirmCancel() {
        guard let current = session else { return }
        let (next, events) = SessionEngine.reduce(current, .cancel(confirmed: true))
        session = next
        stopTicker()
        showCancelConfirmation = false
        handle(events)
        // Not synced here — the confirmation sheet is still in the
        // middle of an animated dismissal at this exact moment
        // (`showCancelConfirmation = false` just started it, hasn't
        // finished it), and resizing/repositioning the parent window
        // while that's happening lost the race: the window kept
        // ending up wherever the sheet's own dismissal left it. See
        // `onSessionSheetDismissed()`, called from the sheet's
        // `onDismiss` once it has actually finished closing.
    }

    func declineCancel() {
        showCancelConfirmation = false
    }

    /// Called from `ActiveSessionView`'s `.sheet(onDismiss:)` — fires
    /// once the Cancel confirmation has actually finished closing,
    /// regardless of which button dismissed it. Safe to call
    /// unconditionally: `syncWindowPlacement` just checks current
    /// session status, so declining (still in progress) is a harmless
    /// no-op here and confirming (now cancelled) is exactly when this
    /// needs to run.
    func onSessionSheetDismissed() {
        syncWindowPlacement()
    }

    func returnToHome() {
        session = nil
        saveFailed = false
        pendingSave = nil
        syncWindowPlacement()
    }

    func dismissInterruptionNotice() {
        showInterruptionNotice = false
        interruptionNoticeSessionID = nil
        interruptionNoticeSessionStartedAt = nil
    }

    // MARK: - Clear Session History (Blueprint §8)

    /// Confirmed Clear History for `scope`, evaluated `asOf` a single
    /// instant the caller captured when the confirmation was presented
    /// — reused for both the count the candidate confirmed and the
    /// actual delete, so the two can't diverge if the dialog sits open
    /// across a day boundary. Debounced like Next / Skip / Cancel
    /// (Blueprint §7) so a rapid double-tap on the destructive confirm
    /// button registers once — on its own timestamp, separate from
    /// session-lifecycle actions on other screens.
    func clearHistory(_ scope: HistoryClearScope, asOf now: Date = Date()) {
        guard clearDebounceOK() else { return }
        performClear(scope, asOf: now)
    }

    /// Drop a stale clear-failure notice — called when Session History
    /// is (re)opened, so a failure from a previous visit doesn't greet
    /// the candidate on return.
    func acknowledgeClearFailure() {
        pendingClearScope = nil
    }

    /// Retry after a failed clear — replays the scope that failed
    /// against a fresh instant. Not debounced, matching `retrySave`:
    /// it's a single recovery button, and it self-limits — a
    /// successful retry clears `pendingClearScope`, so a second tap is
    /// a no-op.
    func retryClear() {
        guard let scope = pendingClearScope else { return }
        performClear(scope, asOf: Date())
    }

    private func performClear(_ scope: HistoryClearScope, asOf now: Date) {
        do {
            let removed = try store.clearHistory(scope, asOf: now)
            pendingClearScope = nil
            handle([.historyCleared(scope: scope, sessionsRemoved: removed)])
            dropInterruptionLinkIfCleared(scope: scope, asOf: now)
        } catch {
            // Blueprint §13: History is untouched (the store's write is
            // all-or-nothing) — surface the retriable notice, keep the
            // scope for Retry.
            pendingClearScope = scope
        }
    }

    /// Blueprint §6/§13: if the interruption notice's linked session was
    /// just removed by this clear, keep the notice text but drop its
    /// now dead `View` link. Checked locally against the same
    /// scope/instant the clear itself just used, rather than re-reading
    /// History from disk a second time.
    private func dropInterruptionLinkIfCleared(scope: HistoryClearScope, asOf now: Date) {
        guard let id = interruptionNoticeSessionID,
              let startedAt = interruptionNoticeSessionStartedAt
        else { return }
        let stub = Session(id: id, startedAt: startedAt)
        if [stub].matching(scope, asOf: now).contains(where: { $0.id == id }) {
            interruptionNoticeSessionID = nil
            interruptionNoticeSessionStartedAt = nil
        }
    }

    func resolveHostWindow(_ window: NSWindow) {
        hostWindow = window
    }

    func retrySave() {
        guard let pending = pendingSave else { return }
        persist(pending)
    }

    /// Blueprint §8 "View Session History" — most recent first,
    /// already guaranteed by `SessionStore`.
    func loadHistory() -> [Session] {
        (try? store.loadHistory()) ?? []
    }

    // MARK: - Live clock

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        guard let current = session, current.status == .inProgress,
              let sessionStart = sessionStartDate, let blockStart = blockStartDate
        else { return }

        let sessionElapsed = Duration.seconds(Date().timeIntervalSince(sessionStart))
        let blockElapsed = Duration.seconds(Date().timeIntervalSince(blockStart))
        let (next, events) = SessionEngine.reduce(
            current, .tick(sessionElapsed: sessionElapsed, activeBlockElapsed: blockElapsed)
        )
        session = next
        handle(events)
    }

    // MARK: - Launch-time interruption check (Blueprint §8, §13)

    private func checkForAbandonedSession() {
        guard let abandoned = try? store.loadAbandonedInProgressSession() else { return }
        let (next, events) = SessionEngine.reduce(abandoned, .interruptionDetected)
        handle(events)
        // Only link the notice's View to a session that's actually in
        // History — if persisting it just failed (handled inside
        // `handle`, above), there's nothing yet for View to show.
        if !saveFailed {
            interruptionNoticeSessionID = abandoned.id
            interruptionNoticeSessionStartedAt = abandoned.startedAt
        }
        showInterruptionNotice = true
        _ = next // already carried inside the sessionSaved event; nothing further to do here
    }

    // MARK: - Event side effects

    private func handle(_ events: [Event]) {
        for event in events {
            switch event {
            case .blockTimeElapsed(let block):
                AlertSound.play()
                AccessibilityNotification.Announcement("\(block) — time's up").post()
            case .sessionSaved(let saved):
                persist(saved)
            case .historyCleared(let scope, let removed):
                Self.log.info("History cleared: \(String(describing: scope), privacy: .public), removed \(removed, privacy: .public)")
            case .sessionStarted, .blockActivated, .blockAdvanced, .blockSkipped,
                 .sessionCompleted, .sessionCancelled:
                break
            }
        }
    }

    private func persist(_ session: Session) {
        do {
            try store.save(session)
            saveFailed = false
            pendingSave = nil
        } catch {
            saveFailed = true
            pendingSave = session
        }
    }

    // MARK: - Window placement
    //
    // Per the designs, an active session is a small, corner-anchored
    // utility window — meant to sit alongside a whiteboard app while
    // practicing, not occupy the whole screen — while Home, Summary,
    // and History are normal full-size document windows. One window,
    // repositioned/resized as the session's status changes, rather
    // than two separate window scenes.

    private func syncWindowPlacement() {
        guard let window = hostWindow else { return }
        if session?.status == .inProgress {
            moveToFloatingCorner(window)
        } else {
            restoreDocumentPlacement(window)
        }
    }

    /// The Active Session card's known, effectively-constant size —
    /// `ActiveSessionView`'s own fixed 320pt width plus its content's
    /// real height, plus ~28pt for the window's native title bar.
    /// Used instead of reading `window.frame.size` after the fact —
    /// see the comment below for why. (Was previously 360×480, a
    /// rough guess that turned out visibly too large in both
    /// dimensions — the window was genuinely smaller than the corner
    /// position had been computed for, leaving a real gap.)
    private static let floatingPanelSize = CGSize(width: 320, height: 360)

    private func moveToFloatingCorner(_ window: NSWindow) {
        // Remember where the document window was so we can put it
        // back exactly, rather than re-centering it every time.
        if documentFrame == nil {
            documentFrame = window.frame
        }
        guard let screen = window.screen ?? NSScreen.main else { return }
        // Set size AND position together, synchronously, right here —
        // not deferred to the next run loop tick waiting for
        // `.windowResizability(.contentSize)` to settle first. That
        // deferral was visible as a two-step flash: SwiftUI would
        // cross-fade the content in at the *old* (Home-sized) window
        // frame, and only a beat later would the window actually
        // shrink and jump to the corner. Computing the target frame
        // from this view's known size instead of observing it after
        // the fact means the window is already correct before the
        // content swap even renders.
        let margin: CGFloat = 16
        let size = Self.floatingPanelSize
        let origin = CGPoint(
            x: screen.visibleFrame.maxX - size.width - margin,
            y: screen.visibleFrame.maxY - size.height - margin
        )
        window.setFrame(NSRect(origin: origin, size: size), display: true, animate: false)
    }

    private func restoreDocumentPlacement(_ window: NSWindow) {
        guard let frame = documentFrame else { return }
        documentFrame = nil
        // Restore the whole frame, not just the origin. Origin-only
        // left `.windowResizability(.contentSize)` free to resize the
        // window for Summary's larger content however it saw fit —
        // its resize anchor didn't match my assumption, so the window
        // often settled back near the corner instead of at the
        // restored origin. Setting the full frame here removes that
        // ambiguity the same way `moveToFloatingCorner` already does.
        window.setFrame(frame, display: true, animate: false)
    }

    // MARK: - Debounce (Blueprint §7: rapid repeats register once)

    private func debounceOK() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastActionAt) > 0.3 else { return false }
        lastActionAt = now
        return true
    }

    /// Clear History's own debounce — kept separate from `debounceOK()`
    /// so confirming a clear can't suppress an unrelated action on
    /// another screen shortly after (e.g. the empty state's Start
    /// Session button, which can appear immediately once History is
    /// cleared to zero).
    private func clearDebounceOK() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastClearActionAt) > 0.3 else { return false }
        lastClearActionAt = now
        return true
    }
}
