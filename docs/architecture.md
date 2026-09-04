# Technical Plan: Interview Timer (macOS v1 / iOS v2+)

**Status:** v1 shipped — all 6 phases complete, 29 passing tests, packaged as a real .app, 9/9 Blueprint contracts conform (see §12)\
**Source of truth for behavior:** `application-blueprint.md` (rev. 12)\
**Scope of this document:** How we build it — architecture, data
model, testing, and a phased build order. This document does not
redefine behavior; where it needs to reference behavior, it cites the
Blueprint section rather than restating it.

------------------------------------------------------------------------

## 1. Platform & Stack

- **v1:** native macOS app, SwiftUI + AppKit interop where needed
  (custom title bar / menu chrome to match the high-fidelity designs).
- **v2/v3:** native iPhone companion app, SwiftUI, sharing the same
  core logic as macOS (Blueprint §12).
- **No** Android, web, or Windows/Linux target. No backend — the app
  is fully local (Blueprint §7).
- **Minimum OS target:** macOS 26 (Tahoe) / iOS 26 — the current OS
  generation. No back-compat shims needed; free to use the latest
  SwiftUI APIs (`@Observable`, the newest `NavigationSplitView`/
  `.glassEffect`-era APIs, etc.) without qualification.
- **Distribution (v1):** direct local build-and-run via Xcode — no
  App Store submission, no notarized `.app`/`.dmg` yet. This means no
  paid Apple Developer Program enrollment is required to get started;
  a free personal-team signing identity is enough to build and launch
  on this Mac. App Store / notarized distribution is a later decision,
  not a v1 blocker.
- **Product name:** `Interview Timer` — already the in-app title per
  Blueprint §10; now also the shipping app/bundle name.
- **Bundle identifier:** `com.eebaez.interviewtimer`.

------------------------------------------------------------------------

## 2. Project structure

A single Swift Package Manager workspace, one shared package and two
app targets (the second not built until v2):

```
InterviewTimer/
├── Package.swift
├── Sources/
│   └── TimerCore/            # pure Swift, no UI, no platform APIs
│       ├── Models/           # Session, Block, enums
│       ├── Engine/           # state machine, timer ticking
│       ├── Persistence/      # SessionStore protocol + JSON impl
│       └── Events.swift
├── Tests/
│   └── TimerCoreTests/       # one test group per Behavioral Contract
├── TimerMac/                 # SwiftUI macOS app target (v1)
│   ├── Views/
│   ├── Audio/
│   └── TimerMacApp.swift
└── TimerIOS/                 # SwiftUI iOS app target (v2/v3, later)
```

**Why a shared core package first:** everything in Blueprint §6–§9
(states, rules, behavioral contracts, events) has zero platform
dependency — it's pure data and logic. Isolating it in `TimerCore`
means the iOS app in v2 is "write the Views, reuse the engine," not a
second implementation of the same rules that can drift from the
first. It's also what makes the engine unit-testable without a
simulator or a running app.

------------------------------------------------------------------------

## 3. Data model

Maps directly onto Blueprint §6 (States) and §9 (Events) — this is a
translation, not a new design.

```swift
enum SessionStatus { case notStarted, inProgress, completed, cancelled }

enum BlockOutcome { case upcoming, active, done, skipped, notReached }

struct Block {
    let name: String          // "Requirements", "Core Entities", …
    let baseline: Duration    // 5m / 5m / 5m / 5m / 15m / 10m
    var outcome: BlockOutcome
    var timeSpent: Duration?
    var wasAlerted: Bool      // time elapsed while this block was active
}

struct Session {
    let id: UUID
    let startedAt: Date
    var status: SessionStatus
    var blocks: [Block]       // always all six, per Blueprint §7
    var elapsed: Duration     // session-level, counts up
    var cancelledAtBlock: String?
    var wasInterrupted: Bool
}
```

The six blocks and their baselines (Requirements 5m, Core Entities 5m,
API/System Interface 5m, Data Flow 5m, High-Level Design 15m, Deep
Dives 10m — 45m total) are a constant in `TimerCore`, not
configuration — matches the Blueprint's "single fixed template, no
customization in v1" decision (§15).

------------------------------------------------------------------------

## 4. The engine: state machine + events

A single reducer-style function is the entire implementation surface
for Blueprint §8:

```swift
func reduce(_ session: Session, _ action: Action) -> (Session, [Event])
```

**As built:** `Action` is `start`, `tick(sessionElapsed:activeBlockElapsed:)`,
`advance`, `skip`, `cancel(confirmed: Bool)`, `interruptionDetected` —
6 cases covering the 6 state-mutating Behavioral Contracts (the other
2 contracts in §8, View Session History and Review Session Detail,
are pure reads over `SessionStore` and never touch the reducer).
`blockTimeElapsed` turned out not to need its own action: `tick`
carries both the session-level and active-block elapsed durations
from whatever's driving the live clock, and the reducer itself
detects the baseline crossing and emits `Event.blockTimeElapsed` —
exactly once, tracked via a `wasAlerted` flag on the block, never
re-fired by a later tick. This keeps the reducer pure and trivially
testable: tests pass synthetic `Duration` values directly, no real
waiting, no clock mocking. `Event` is the exact 8-case enum from
Blueprint §9. All 6 contracts plus the guard/edge cases the Blueprint
calls out explicitly (no minimum time before Advance, Skip only valid
on Data Flow, Cancel decline is a true no-op, interruption only from
`inProgress`) are covered by `SessionEngineTests` — 19 tests, all
passing.

This is the highest-leverage design choice in the whole plan: because
the Blueprint already specifies triggers and expected behavior as
discrete, enumerable contracts, the engine has no ambiguity to resolve
— it's a direct transcription. **Conformance Review against §8 is
just "does every contract have a passing test."**

The actual per-second `tick` dispatch — a `Timer`/`DispatchSourceTimer`
comparing against wall-clock `Date` rather than counting ticks, so a
dropped frame or a slow tick never causes drift — is UI-layer wiring,
not engine logic, and is built in Phase 2 alongside the views that
need a live clock.

------------------------------------------------------------------------

## 5. Persistence

**Proposed: a single JSON file**, not Core Data or SwiftData — the
data is small (a handful of fields × up to a few hundred records over
realistic use) and has no relational structure or query needs beyond
"list, most recent first" (Blueprint §10). A `SessionStore` protocol
with a `JSONFileSessionStore` implementation keeps this swappable if
that judgment turns out wrong later, and keeps `TimerCore` free of a
persistence-framework dependency that would need to exist identically
on both macOS and iOS.

- Location: `Application Support/InterviewTimer/sessions.json` (macOS
  equivalent sandbox path on iOS later).
- Write points: on `SessionSaved` (Completed or Cancelled) per §8/§9.
- The abandoned-session check (Blueprint §7/§8 "Interruption
  Detected") is a single flag file or a `status: .inProgress` record
  left over from a prior run — checked once at launch, nowhere else,
  per Blueprint §13 ("brief backgrounding is not an interruption").
- `SessionSaved` failure handling (Blueprint §8, §13: never blocks the
  Summary screen) means every write is fire-and-forget from the UI's
  perspective — the UI reads the in-memory `Session` it already has,
  not a re-read from disk, and shows a retry affordance only if the
  write actually throws.

**Not in scope for v1, flagged for v2/v3:** if the iPhone companion is
meant to see the *same* History as the Mac (not just run its own local
timer), that requires a sync story — iCloud/CloudKit is the natural
fit for two Apple devices, but it's a real Blueprint-level decision
(does History live per-device or per-candidate?) that hasn't been
asked yet. Worth raising before v2 starts, not before v1.

------------------------------------------------------------------------

## 6. Audio

A single bundled short sound asset, played via `AVAudioPlayer` (or
`NSSound` on macOS). Wrapped so a failure to play — muted device,
missing asset, audio session issue — is caught and silently ignored,
never surfaced to the candidate, per Blueprint §7/§13 ("sound is
never the only carrier of the alert"). The visual highlight and
`Time's up` label are dispatched independently of whether the sound
call succeeds.

------------------------------------------------------------------------

## 7. Accessibility implementation notes

Mapping Blueprint §11 to concrete SwiftUI/AppKit mechanisms:

| Blueprint requirement | Implementation |
|---|---|
| `BlockTimeElapsed` announced via live region | `AccessibilityNotification.Announcement` posted on the same dispatch as the visual nudge |
| Never color-only | `Time's up` label + `+overrun` format are real text content, not just a color/style change |
| No flashing | The highlight is a one-time state transition (SwiftUI `.animation` to a held end-state), never a repeating animation |
| Full keyboard operability | Every button is a real `Button`/`.keyboardShortcut`, not a tap-only custom view; `Space` → Next, `Escape` → decline (Blueprint §12) |
| Focus never force-moved on block change | No `@FocusState` mutation on block transitions — only on dialog open/close |
| Cancel confirmation traps focus, returns it on dismiss | Native SwiftUI `.sheet`/`.alert` presentation — this is free from AppKit/SwiftUI's built-in modal focus handling, not something to hand-build |

This table is the accessibility checklist for QA before v1 ships —
each row should be independently verifiable with VoiceOver on.

------------------------------------------------------------------------

## 8. Open technical questions

Resolved: minimum OS version (macOS 26 / iOS 26), distribution (direct
local build-and-run, no App Store for v1), product name
(`Interview Timer`), and bundle identifier
(`com.eebaez.interviewtimer`) — see §1.

Nothing left open that blocks Phase 0. The only remaining question is
forward-looking, not urgent:

- **iCloud sync for History**, once v2/iPhone is real (§5 above) — a
  Blueprint-level question, not just a technical one.

------------------------------------------------------------------------

## 9. Testing strategy

- **`TimerCoreTests`**: one test group per Behavioral Contract (§8) —
  8 contracts, each with its happy path plus the edge cases the
  Blueprint already calls out explicitly (double-tap debounce, Skip
  only valid on Data Flow, Cancel decline leaves state unchanged,
  interruption detection only at launch). This is the bulk of
  automated coverage and needs no UI, simulator, or device.
- **Manual QA pass against `application-blueprint.md` §10 (Copy)**:
  every string in the shipped UI should trace to a line in that
  section — this is effectively a lightweight Conformance Review,
  repeatable each time the UI changes.
- **VoiceOver pass against §11**, using the table in §7 above as the
  checklist.
- Snapshot/UI tests are a nice-to-have, not a v1 requirement given the
  small screen count (7) and the existing high-fidelity designs as the
  visual reference.

------------------------------------------------------------------------

## 10. Phased build order

``` text
Phase 0 — Scaffolding ✅ Done
  SPM workspace, TimerCore skeleton, TimerMac shell app. Built,
  launched, and visually confirmed on-screen.

Phase 1 — Engine, no UI ✅ Done
  Full state machine (§4) + JSON persistence (§5) implemented and
  unit-tested against TimerCore alone — 25 passing tests. Verified
  entirely without opening a window.

Phase 2 — Home + Active Session ✅ Done
  Start Session, the countdown/elapsed display, Next/Skip/Cancel, the
  Time's Up nudge. Pulled the Cancel confirmation dialog forward from
  Phase 3 — a Cancel button with no confirmation behind it wouldn't
  actually satisfy its own Behavioral Contract, so it wasn't a smaller
  version of Phase 2, it was an incomplete one. Summary itself
  (Completed & Cancelled) is still a temporary placeholder pending
  Phase 3. First point the app is genuinely usable end-to-end for a
  full session — verified by hand.

  Build note: a plain SPM-built executable doesn't get proper
  NSApplication activation when launched outside Finder (no .app
  bundle yet — that's Phase 6). Windows still accept mouse clicks but
  don't reliably become key, so keyboard shortcuts silently failed
  despite looking correct in code. Fixed with an explicit
  `AppDelegate` (`NSApp.activate`) plus `.onKeyPress` as a second
  layer alongside `.keyboardShortcut`. Worth re-confirming once Phase
  6 produces a real .app bundle, in case bundling changes this.

Phase 3 — Summary ✅ Done
  Real Summary screens (Completed & Cancelled) — stat block, per-block
  breakdown table, Skipped badge, save-failure retry notice — replacing
  the temporary SessionEndedPlaceholderView. Extracted the block
  progress bar into a shared `BlockProgressBar` component, now used by
  both Active Session and Summary.

  Bug found and fixed: `SummaryView`, `ActiveSessionView`, and
  `CancelConfirmationView` all force-unwrapped `model.session!`.
  Tapping Done set `model.session = nil`; SwiftUI re-evaluated
  SummaryView's body once more before RootView swapped it out,
  crashing on that transient nil (confirmed via the actual crash
  report — EXC_BREAKPOINT/SIGTRAP). Fixed by passing `session` down
  as a plain value from RootView's already-safe `if let` instead of
  each child re-deriving it from the live optional. Worth keeping as
  a standing pattern for any future view driven by `model.session`.

Phase 4 — History & Detail ✅ Done
  Session History list (with the real empty state, verified against a
  freshly cleared store) and Session Detail, both built on a new
  shared `SessionBreakdownView` extracted from Summary — the two
  screens render identical content per Blueprint §10 ("same format as
  the corresponding Summary above"), not a re-implementation. Detail's
  `Done` pops back to the list; the list's own `Done` closes the sheet.

  Investigated a reported calculation discrepancy — verified correct,
  not a bug: a 17-second QA test session legitimately produces a
  ~-44m delta against the 45m target. Root-caused with a real decode
  script using TimerCore's own Duration Codable, not assumption.
  Cleared the QA-artifact sessions from the real Application Support
  store afterward so History starts clean for actual use.

Phase 5 — Accessibility & polish
  Closed out every row of §7's table: icon-only controls got explicit
  labels, fragmented text (block rows, the block table, History rows,
  headers) got combined into single coherent elements instead of
  reading as scattered fragments, and the Time's Up nudge gained a
  real steady-highlight treatment (a border, not just text color) —
  animated when motion is allowed, instant otherwise, gated on
  `accessibilityReduceMotion` throughout. Keyboard-only pass confirmed
  by construction: every control is a real `Button` (no
  `.onTapGesture`), audited directly.

  Guided visual QA pass against the designs, screenshots relayed by
  the user each round since I can't capture my own:
  - Start Session sized up and switched to an ink-colored fill
    (`.tint(.primary)`, adapts light/dark) instead of the default
    blue accent.
  - Summary/Detail header rebuilt with `Grid` so the title/date row
    baseline-aligns with the elapsed-time digits, and the subline
    aligns with the delta — mismatched-width columns sharing real
    row baselines, not two independently-stacked blocks.
  - Home's template preview is two columns (column-major: first
    three blocks left, last three right), matching the design;
    fixed a real bug alongside it where the intro text was silently
    truncating to "solo, again…" in a too-tight VStack.
  - Fixed Session Detail rendering vertically centered (with dead
    space top and bottom) inside History's fixed-size sheet — pinned
    to top-leading instead.
  - Bigger finding: the designs use two distinct window treatments,
    not one. Home/Summary/History are normal document windows
    (already close to this from Phase 2-4); Active Session and the
    Cancel dialog are a small floating card anchored to a screen
    corner with a custom menu bar — implying the timer is meant to
    sit alongside a whiteboard app while practicing, not occupy the
    screen. Confirmed with the user: build the floating-window
    behavior (kept the single-window architecture — one `NSWindow`,
    repositioned via `WindowAccessor` + `AppModel.syncWindowPlacement`
    rather than a second `Window` scene), skip the custom menu bar
    for v1 (contents were never specified anywhere in the Blueprint).

  Guided visual QA continued — more rounds, more fixes:
  - App title was "TimerMac" (the raw executable name, since there's
    no real .app bundle yet); set explicitly to "Interview Timer".
  - Start Session, Next, Keep going, and all three `Done` buttons
    unified onto one ink-colored pill style (`primaryPillStyle()`);
    Session History/Skip block/Cancel session/the interruption
    banner's View link unified onto one muted underlined style
    (`LinkButton`) — replacing the system's default blue link color,
    which the design doesn't use anywhere. Factored into a shared
    `ButtonStyles.swift` so these don't drift independently again.
  - A block's per-block time now goes orange when it individually
    exceeds its own baseline (Summary/Detail), matching the design —
    this was previously invisible, always rendered in the same muted
    gray regardless of overrun. Same fix applied to History rows'
    delta, which was hardcoded to `.secondary` regardless of sign.
  - Real behavior fix, not styling: skipping Data Flow was discarding
    `timeSpent` entirely, so any time elapsed before the skip vanished
    from the per-block breakdown while still counting toward the
    session total — sessions where Data Flow was skipped after any
    real time had passed would show a "the math doesn't add up" gap
    between the total and the visible per-block sum. Root-caused by
    computing both from a real screenshot rather than guessing, fixed
    in the engine (`SessionEngine.skip` keeps `timeSpent` now) with a
    matching Blueprint decision (§15) since it refines an existing
    rule, not just a UI tweak.
  - Session History's sheet was one fixed 600×560 frame shared by both
    the list and Detail; since Detail's content height is roughly
    constant, this always left dead space for it. Fixed by letting
    each screen size to its own content again (list gets an explicit
    min/max scrollable height; Detail sizes naturally) — same pattern
    as the main window already uses between Home/Active
    Session/Summary.
  - Applied the design's exact palette instead of system defaults —
    pixel-sampled from the actual mockups (via a temp Pillow install,
    not eyeballing) rather than assumed: background `#faf9f6` /
    `#1b2027`, ink `#1f2933` / `#e7eaee`, ink-soft, ink-tertiary, and
    the accent orange, each with confirmed light/dark hex values. New
    `Theme.swift` + a `.themedSurface()` modifier applied to every
    screen, replacing `.secondary`/`.tertiary`/`.orange`/default
    background throughout.
  - Fixed a visual flash entering/leaving Active Session: the window
    reposition was deferred one run-loop tick to wait for
    `.windowResizability(.contentSize)` to settle the new size first,
    so SwiftUI would cross-fade the content in at the *old* window
    frame, then a beat later the window would jump to its corner.
    Fixed by computing size and position together, synchronously,
    from the Active Session card's known/predictable size instead of
    reading it back after the fact. The flash itself turned out to be
    mostly the content cross-fade animation, not the window move —
    removed it entirely for these transitions (Home/Active
    Session/Summary are structurally too different to fade between
    cleanly; a hard cut reads better than a glitchy blend).
  - Completing a session correctly restored the window to Home's
    original spot; cancelling didn't — it stayed at the corner.
    Root cause: `confirmCancel()` dismisses the Cancel confirmation
    sheet in the same call where it also repositions the window, and
    sheet dismissal is itself animated/asynchronous in AppKit — the
    synchronous window move was racing that dismissal and losing.
    Completing has no sheet in the way, which is exactly why only
    that path worked. Fixed by moving the placement sync into the
    sheet's `onDismiss` callback (`AppModel.onSessionSheetDismissed`),
    so it only runs once the sheet has actually finished closing —
    safe to call unconditionally since it just checks current session
    status regardless of which button dismissed the sheet.
  - The corner position itself was visibly off (a real gap, not just
    close) — `floatingPanelSize` was a rough 360×480 guess, but
    `ActiveSessionView` actually rendered closer to 320×300, since its
    width was a `minWidth...maxWidth` *range* rather than a fixed
    value. Fixed at the source: the view's width is now fixed (not a
    range), and the AppModel estimate was corrected to match reality
    (320×360) instead of re-guessing further.

  Still open: audio is the placeholder system sound from Phase 2, not
  a bundled custom asset — fine functionally, a real asset is a
  Phase 6-or-later nice-to-have.

Phase 6 — Package & ship v1 ✅ Done
  `scripts/package-app.sh` builds a release binary, assembles a real
  Interview Timer.app (Info.plist, bundle ID, ad-hoc code signature),
  and verifies the signature — no Xcode project needed, this stayed a
  pure SPM package throughout. Output lands in `dist/`. Local
  build-and-run only, per the standing decision — no App Store, no
  paid Developer Program membership, notarized distribution left as a
  later option if this ever needs to leave this Mac. Blueprint
  Conformance Review: see §12 below — 9/9 contracts conform.

  App icon: a bold stopwatch glyph on the app's actual ink/navy
  gradient with the accent orange on one hand and the pivot — same
  palette `Theme.swift` uses, not a separate icon-only choice.
  Deliberately not the thin SF Symbol clock outline used in-app
  (Home's header icon); that doesn't read at 16×16 in the Dock.
  Generated with a one-off Pillow script (no SVG renderer was
  available) rather than hand-tuning a bitmap; the generator itself
  wasn't kept — `AppIcon-1024.png` is the tracked source asset now,
  the same way `docs/artifacts/designs` holds the Product Designer's
  mockups as final exports, not the tool that made them. Compiled to
  `.icns` via `scripts/build-icns.sh` (macOS's built-in sips/iconutil,
  kept since it's generic PNG→icns packaging, not design generation),
  and wired into `package-app.sh` automatically.
```

Each phase produces something runnable — nothing is a "big bang"
integration at the end.

------------------------------------------------------------------------

## 11. Relationship to the Blueprint

Per the Application Blueprint spec's own model: this document is
Engineering's technical design, not part of the Blueprint. It answers
*how* to build the behavior the Blueprint already defines; it doesn't
redefine *what* that behavior is. If something in here turns out to
need a behavior change (not just an implementation choice), that
change belongs in `application-blueprint.md` first, with this document
updated to follow it — not the other way around.

------------------------------------------------------------------------

## 12. Blueprint Conformance Review (v1)

Per the Blueprint spec's own definition (§11 of
`application-blueprint.md`): does the built app match the agreed
behavioral contract? All 9 of Blueprint §8's Behavioral Contracts,
checked against automated test coverage plus real manual use across
this whole build (not just at the moment of packaging):

| Contract | Automated coverage | Manual verification |
|---|---|---|
| Start Session | `startMovesToInProgressAndActivatesRequirements`, `startIsANoOpIfAlreadyInProgress` | Home → Start Session, repeatedly |
| Block Time Elapses | `tickPastBaselineFiresBlockTimeElapsedExactlyOnce`, `tickBelowBaselineDoesNotFireAlert` | Sound + steady orange highlight confirmed live |
| Advance to Next Block | `advanceMarksCurrentDoneAndActivatesNext`, `advanceHasNoMinimumTime`, `advanceIsANoOpWhenNotInProgress` | Space/Next through full sessions |
| Skip Block | `skipMarksDataFlowSkippedAndActivatesHighLevelDesign`, `skipPreservesTimeSpentBeforeTheSkip`, `skipIsANoOpOnAnyOtherBlock` | Skip Data Flow after real elapsed time; totals reconcile |
| Complete Session | `advancingPastDeepDivesCompletesTheSession` | Summary — Completed, multiple real sessions |
| Cancel Session | `cancelConfirmedEndsSessionAndMarksUpcomingNotReached`, `cancelDeclinedLeavesStateUnchanged`, `cancelIsANoOpWhenNotInProgress` | Confirm and decline paths, including the window-placement bug found and fixed along the way |
| Interruption Detected | `interruptionDetectedBehavesLikeConfirmedCancelButMarkedInterrupted`, `inProgressMarkerIsRecoverableAsAbandoned`, `savingClearsTheInProgressMarker` | Reproduced with a crafted abandoned session; correctly auto-cancelled and surfaced on Home |
| View Session History | *(pure read — no engine test)* | List, empty state, most-recent-first order, delta coloring by sign |
| Review Session Detail | *(pure read — no engine test)* | History → row → Detail; Done pops to list, List's own Done closes the sheet |

**Result: 9/9 contracts conform.** 29 automated tests all passing.
No open discrepancies between built behavior and the Blueprint as of
rev. 13.

Outside §8, worth naming explicitly since they came from real use
rather than the original plan: the exact color palette (§Theme.swift,
pixel-sampled from the designs, not system defaults), the two-window-
treatment split (small floating Active Session vs. full-size document
windows) confirmed with the user during Phase 5, and the skip-time
reconciliation decision logged in the Blueprint (§15) after real usage
surfaced it. All three are reflected in both the Blueprint and this
plan — nothing shipped that the documentation doesn't know about.
