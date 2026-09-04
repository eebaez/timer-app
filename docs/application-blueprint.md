# Application Blueprint: System Design Interview Timer

**Resolution Stage:** 99% — Refinement\
**Last updated:** 2026-09-04 (rev. 14 — Clear Session History folded in)\
**Status:** Live — the authoritative source of truth for behavior, kept current as features land

------------------------------------------------------------------------

## 1. Application Intent

Help candidates preparing for system design interviews build accurate
time discipline by practicing solo against a realistic, phase-based
interview clock.

------------------------------------------------------------------------

## 2. Actors

- **Candidate** — the sole actor. Uses the app alone to rehearse pacing
  through a system design interview.

------------------------------------------------------------------------

## 3. Capabilities

- Start a Practice Session
- Advance to Next Block (manual)
- Skip a Block (Data Flow only, in the moment)
- Cancel Session
- View Session History
- Review a Past Session's Detail
- Clear Session History

------------------------------------------------------------------------

## 4. Entry Points

- **Home / Dashboard** — start a new practice session
- **Session History** — review past sessions

------------------------------------------------------------------------

## 5. Major Journeys

**Primary journey — full practice session:**

``` text
Home
  ↓
Start Session
  ↓
Requirements (5m)
  ↓
Core Entities (5m)
  ↓
API / System Interface (5m)
  ↓
Data Flow (5m) [Skip available in the moment]
  ↓
High-Level Design (15m)
  ↓
Deep Dives (10m)
  ↓
Session Complete → Summary
  ↓
Saved to History
```

**Alternate — Data Flow skipped:**

``` text
… API / System Interface → [Skip] Data Flow → High-Level Design …
```

**Alternate — cancel:**

``` text
Session In Progress → Cancel (confirm) → Summary (not completed) → Saved to History
```

**Alternate — interrupted (no explicit action):**

``` text
Session In Progress → app closed / refreshed → reopened at Home
  → abandoned session auto-recorded as Cancelled → one-time notice on Home
  → Saved to History
```

**Alternate — review the past:**

``` text
Session History → Select Session → Session Detail
```

**Alternate — clear history:**

``` text
Session History → Clear History (menu) → Older than 30 days | Older than 90 days | All Time
  → Confirm → Session History (updated list, or empty state)
```

``` text
Session History → Clear History → choose scope → Keep History (or Escape)
  → Session History, unchanged
```

------------------------------------------------------------------------

## 6. States

**Session:** Not Started → In Progress → Completed | Cancelled

**Block (within a session):** Upcoming → Active → Active (alerted —
time elapsed, awaiting advance) → Done | Skipped (Data Flow only) |
Not Reached (only when the session is Cancelled or interrupted while
the block was still Upcoming)

------------------------------------------------------------------------

## 7. Rules and Constraints

- The default template is a fixed, ordered sequence of six blocks:
  Requirements (5m), Core Entities (5m), API / System Interface (5m),
  Data Flow (5m), High-Level Design (15m), Deep Dives (10m) — 45m
  total. Data Flow is included by default and can be skipped in the
  moment when it becomes active.
- Block durations are baselines, not hard caps, and are not
  individually pass/fail. The app alerts when a block's time elapses
  but never forces the candidate off that block. They're exact values
  (not ranges) so a candidate can track proficiency against them
  consistently across sessions — but they remain guidance, not a
  requirement to hit.
- The real success criterion lives at the **session** level, not the
  block level: did the candidate complete the full design (all
  non-skipped blocks) within the overall session time budget (sum of
  block baselines, 45m by default)? A candidate who reallocates time
  across blocks but finishes the design within budget has succeeded.
- There is no pause/resume. A session is either carried through to
  completion or cancelled outright — cancelling does not preserve
  progress to resume later.
- During an active session, the candidate sees both the current
  block's countdown and the running total session-elapsed time.
- When a block's time elapses, the app nudges (not interrupts) the
  candidate: a highlight/color change on the active block plus a
  single alert sound — oriented toward awareness, not distraction.
- Advancing to the next block is available at any time a block is
  Active — never gated by that block's own countdown elapsing. This
  follows directly from the session-level success model: a confident
  candidate can move on early, exactly as in a real interview.
- A block that is **Skipped** is recorded distinctly from a block that
  is **Done**. Skip applies to Data Flow only — every other block must
  be advanced through (even after only a few seconds) rather than
  skipped.
- The session target stays at the full 45m regardless of whether Data
  Flow is skipped — it is never recalculated down to 40m for a session
  that skips it. The target represents the whole interview structure;
  skipping a block just means finishing with more slack.
- Cancelling requires a confirmation step, since it forfeits the
  session as a counted attempt. The confirmation shows how far into
  the session the candidate is (elapsed time and current block) so
  the decision is informed.
- An interrupted session — the app is closed or refreshed mid-session
  with no explicit Cancel or Completion — is auto-recorded to History
  as Cancelled the next time the app opens. There is no session to
  resume into; the candidate lands on Home.
- The alert (highlight + sound) is a nudge, not a requirement: if
  sound cannot play (device muted, audio blocked), the visual
  highlight alone must still convey the alert. Sound enhances the
  signal; it is never the only carrier of it.
- Every block in a session's record — including Not Reached blocks in
  a Cancelled session — is represented in that session's per-block
  breakdown, so History always shows the full six-block shape rather
  than a partial list.
- Session History is local to the candidate's device. v1 has no
  accounts or authentication, so history does not sync across
  devices.
- The alert highlight is a single steady state change, never a
  blink/pulse loop — legible without relying on color perception, and
  free of flashing that could distract or, at worst, trigger a
  photosensitive reaction.
- Rapid repeated activation of Next, Skip, or Cancel (e.g. a double
  tap) registers as a single action — never as two block advances or
  two cancel attempts from one input.
- The `Cancel session` control is spatially and visually separated
  from `Next`, and the cancel confirmation defaults to the
  non-destructive choice, so a mis-tap can't discard a real attempt.
- The Skip control is only ever shown while Data Flow is the active
  block; it never appears for any other block.
- **Clear History** acts only on saved History records. It never
  touches an in-progress session or the abandoned-session marker used
  for interruption detection — those are a separate store, untouched
  by a clear.
- "Clear older than X days" is a retention/prune model: it removes
  sessions *older* than X days and keeps recent ones — not a wipe of
  the last X days. The trigger for the feature is accumulation, not
  privacy; a candidate pruning old throwaway sessions wants to keep
  recent history for pacing trends.
- The `Clear History` control is hidden when History is empty — no
  dead-end control for nothing to clear.
- A day-range scope that currently matches zero sessions is omitted
  from the Clear History menu rather than shown disabled — a candidate
  is never offered a scope that would be a confirmed no-op. `All Time`
  is always present whenever the control is shown.
- Each scope in the menu carries the count of sessions it would
  remove, so the size of the action is visible before the confirmation
  opens.
- The Clear History confirmation always names the exact number of
  sessions the chosen scope will remove and states plainly that the
  action can't be undone. Its default-focused choice is the
  non-destructive one (`Keep History`) and its destructive button is
  visually distinct — the same defensive pattern as the Cancel
  confirmation. `All Time` uses this same single-confirm pattern as the
  day-range scopes, with no extra step (e.g. typing "DELETE") — the
  named count plus "can't be undone" wording is the safeguard.
- Rapid repeated activation of the destructive confirm button
  registers once — same debounce rule as Next, Skip, and Cancel.
- If the one-time interruption notice is still showing and a clear
  action removes its linked session, the notice keeps its dismissible
  text but drops its `View` link rather than pointing at a session
  that no longer exists.
- Day-range thresholds are fixed presets (30 / 90 days), not a
  free-typed number — consistent with the app's "no candidate-entered
  form data" posture. This is settled: there is no plan to make the
  thresholds adjustable.

------------------------------------------------------------------------

## 8. Behavioral Contracts

``` text
Action:
Start Session

Expected behavior:
- Move the Session to In Progress.
- Activate the first block, Requirements, with its baseline countdown.
- Start the session-level elapsed timer at 0:00, counting up.
- Emit SessionStarted, then BlockActivated(Requirements).
```

``` text
Action:
Block Time Elapses (system-driven, not a candidate action)

Expected behavior:
- Keep the block Active — never auto-advance.
- Enter the block's "alerted" sub-state: a steady (non-blinking)
  highlight, a "Time's up" text label, one alert sound, and the
  countdown switching to a "+" overrun format (e.g. +0:45).
- Emit BlockTimeElapsed(block).
```

``` text
Action:
Advance to Next Block ("Next")

Expected behavior:
- Mark the current block Done, recording the time actually spent on it.
- Activate the next block in sequence with its own baseline countdown.
- Emit BlockAdvanced(fromBlock, toBlock, timeSpent).
- If the current block is Deep Dives, trigger Complete Session instead
  of activating a next block.
- A rapid repeat tap within the debounce window has no additional
  effect.
```

``` text
Action:
Skip Block ("Skip block") — Data Flow only

Expected behavior:
- Mark Data Flow Skipped (distinct from Done — not counted as an
  attempt against its baseline). Whatever time had already elapsed
  on it before the skip is kept, not discarded, so the session's
  total always reconciles with its per-block breakdown.
- Activate High-Level Design with its baseline countdown.
- Emit BlockSkipped(DataFlow).
```

``` text
Action:
Complete Session

Expected behavior:
- Mark the final block (Deep Dives) Done.
- Move the Session to Completed and stop the session-elapsed timer.
- Show a Summary: total elapsed vs. the 45m target (with signed
  delta), per-block time spent vs. baseline for all six blocks, and
  which block (if any) was skipped.
- Emit SessionCompleted, then SessionSaved.
- If SessionSaved fails, show the Summary in full regardless, with a
  small retriable inline notice — saving failure never blocks or
  hides the candidate's result.
```

``` text
Action:
Cancel Session

Expected behavior:
- Show a confirmation naming the elapsed time and current block, with
  "Keep going" as the default-focused choice.
- On confirm: stop the current block's timer, mark any Upcoming blocks
  Not Reached, and move the Session to Cancelled.
- Show a Summary labeled Cancelled, with total elapsed vs. the 45m
  target (with signed delta, same as a Completed session) and
  per-block data for whatever was reached.
- Emit SessionCancelled(atBlock, interrupted: false), then SessionSaved.
- On decline (or Escape): dismiss the confirmation and resume exactly
  where the candidate was — no state change.
```

``` text
Action:
Interruption Detected (system-driven, on app launch)

Expected behavior:
- Detect an abandoned In Progress session left by a prior run.
- Auto-apply the same behavior as Cancel Session, using whatever
  block progress had been recorded, with interrupted: true.
- Land the candidate on Home with a one-time notice explaining what
  happened; there is no session to resume into.
- Emit SessionCancelled(atBlock, interrupted: true), then SessionSaved.
```

``` text
Action:
View Session History

Expected behavior:
- Show past sessions, most recent first.
- Each row shows: date, total elapsed vs. target (with signed delta),
  and status (Completed / Cancelled).
- If there are no sessions yet, show an empty state that offers
  Start Session directly rather than a dead end.
```

``` text
Action:
Review Session Detail

Expected behavior:
- Show the full record for one past session: total elapsed vs.
  target, and all six blocks with their outcome (Done / Skipped / Not
  Reached) and time spent where applicable.
```

``` text
Action:
Open Clear History Menu

Expected behavior:
- Available only when Session History has at least one saved session.
- List up to three scopes — "Older than 30 days", "Older than 90
  days", "All Time" — omitting any day-range scope that currently
  matches zero sessions. "All Time" is always present.
- Show, against each listed scope, the number of sessions that scope
  would remove (recomputed live, same rule as the confirmation count).
- A divider separates the day-range scopes from "All Time". When every
  day-range scope is omitted (all sessions fall inside 30 days), the
  menu is just "All Time" with no divider. When one day-range scope
  remains, the divider still sits between it and "All Time".
- Does not mutate any state; purely opens the menu.
```

``` text
Action:
Confirm Clear History

Expected behavior:
- Permanently delete every saved session matching the chosen scope:
  all sessions (All Time), or every session whose startedAt is older
  than (now − N days) for the chosen N. A session exactly on the
  boundary is kept.
- Sessions inside the retained window (or all sessions, for a
  day-range scope that matches none) are left untouched.
- Any session currently In Progress, and the abandoned-session marker,
  are unaffected regardless of scope.
- If the interruption notice's linked session was just removed, drop
  its View link (the notice itself stays if still otherwise eligible).
- Return to the Session History list — showing the empty state if that
  was the last session removed.
- Emit HistoryCleared(scope, sessionsRemoved).
- If the underlying delete fails (e.g. disk I/O error), History is
  left exactly as it was before the attempt — never partially
  cleared — and a small retriable inline notice is shown, the same
  pattern as a failed SessionSaved: "Couldn't clear history." with
  Retry.
- A rapid repeat tap within the debounce window has no additional
  effect.
```

``` text
Action:
Decline Clear History (or Escape)

Expected behavior:
- Dismiss the confirmation. No state change — History is untouched.
```

------------------------------------------------------------------------

## 9. Events

- **SessionStarted** — a new practice session began.
- **BlockActivated** `{ block }` — a block became the active one.
- **BlockTimeElapsed** `{ block }` — a block's baseline countdown hit
  0:00; the block remains Active. Triggers the highlight + sound nudge.
- **BlockAdvanced** `{ fromBlock, toBlock, timeSpent }` — the candidate
  manually moved on.
- **BlockSkipped** `{ block: DataFlow }` — the candidate bypassed Data
  Flow.
- **SessionCompleted** `{ totalElapsed }` — all blocks were carried
  through to Done or Skipped.
- **SessionCancelled** `{ atBlock, interrupted }` — the session ended
  without completion, either by explicit Cancel or detected
  interruption.
- **SessionSaved** `{ sessionRecord }` — a session (Completed or
  Cancelled) was persisted to History.
- **HistoryCleared** `{ scope, sessionsRemoved }` — a clear action
  completed. `scope` is `.allTime` or `.olderThan(days: Int)`.

------------------------------------------------------------------------

## 10. Copy

Exact candidate-facing strings for the behaviors above. Visual styling
(color, type, spacing) stays out of the Blueprint by design — this is
wording only.

**Home**
- Title: `Interview Timer`
- Intro line: `Practice pacing a system design interview, solo, against a realistic clock.`
- Primary button: `Start Session`
- Secondary link: `Session History`
- One-time interruption notice: `Your last session ended unexpectedly and was saved as Cancelled.` — dismissible, with a `View` link to that session's Detail. If a Clear History action removes that session, the notice keeps its text but drops the `View` link.
- Template preview: `TEMPLATE · 6 BLOCKS · 45M` eyebrow, followed by all six blocks with their durations (Requirements 5m, Core Entities 5m, API / System Interface 5m, Data Flow 5m, High-Level Design 15m, Deep Dives 10m). Informational only — it does not let the candidate jump into or reorder a block; `Start Session` always begins at Requirements.

**Shared: block progress bar**
- Appears on: Active session, Time's Up, Summary (Completed and
  Cancelled), Session History (each row), and Session Detail.
- Renders all six blocks as segments in a single horizontal bar, each
  segment reflecting that block's outcome (time spent / skipped / not
  reached) and its relative share of the session.
- Legend (shown on Session History): `time spent`, `skipped`,
  `not reached`.
- Informational only — segments are not interactive; tapping one does
  not navigate to or jump the candidate into that block.

**Active session**
- Position header: `BLOCK {n} OF 6` — the active block's position in
  the fixed sequence (1–6).
- Session header: `SESSION {elapsed}` — the running session-elapsed
  time, counting up, shown alongside the position header.
- Budget line: `baseline {baseline} · of 45m budget` — shown under
  the active block's countdown.
- Overrun countdown format: `+0:45` (once a block passes 0:00)
- Alerted-block label: `Time's up`
- Next button: `Next` (bound to the `Space` key, shown as a `space` hint on the button)
- Skip button (Data Flow only): `Skip block`
- Cancel control: `Cancel session` (small, secondary)

**Cancel confirmation**
- Title: `Cancel this session?`
- Body: `You're {elapsed} into {Block Name}. This session will be saved as Cancelled.`
- Default-focused button: `Keep going`
- Other button: `Cancel session`
- Hint: `esc keeps the session running`

**Summary — Completed**
- Title: `Session Complete`
- Subline: `All six blocks carried through.` — or, if Data Flow was
  skipped: `All six blocks carried through, one skipped by choice.`
- Total: stat block — eyebrow `TOTAL TIME`, the elapsed time as the
  primary figure, `{+/-delta} vs. 45m target` shown below it.
- Per-block row: `{Block Name}` (left) · `{time spent} · {baseline}` (right).
- Skipped row: `{Block Name}` (left, dimmed) · `{time spent before skipping} before skipping` (if any) followed by a `SKIPPED` badge (right). No baseline comparison — it's not an attempt — but the time itself is shown so the total always reconciles with the breakdown.
- Button: `Done`

**Summary — Cancelled**
- Title: `Session Cancelled`
- Total: same stat block as Completed — `TOTAL TIME` eyebrow, elapsed
  time, `{+/-delta} vs. 45m target` below it. Delta is always
  calculated, even when the session didn't finish.
- Subline: `Ended during {Block Name} at {elapsed}.`
- Per-block row (reached): `{Block Name}` · `{time spent} · {baseline}`
- Per-block row (in progress at cancel): `{Block Name}` · `{time spent} · in progress`
- Per-block row (not reached): `{Block Name}` (dimmed) · `Not reached` (dimmed)
- Button: `Done`

**Session History**
- Title: `Session History`
- Row: `{date} · {Completed/Cancelled} · {elapsed} ({+/-delta})` — delta is shown on every row regardless of status; it is never omitted for a Cancelled session. Status is shown as a badge, same as Session Detail below.
- Empty state: `No sessions yet. Start your first practice session from Home.` with a `Start Session` button.
- `Clear History` control — header row, grouped with `Done` at the trailing edge; hidden when the list is empty. Opens a menu rather than acting immediately, so it needs no spatial separation from `Done`.
- Clear History menu items, each with the count of sessions that scope would remove, right-aligned: `Older than 30 days`, `Older than 90 days`, `All Time` — omitting any day-range item with zero matching sessions.

**Clear History confirmation**
- Title: `Clear {N} session{s}?`
- Body — All Time: `This permanently deletes your entire session history — {N} sessions. This can't be undone.`
- Body — day range: `This permanently deletes {N} sessions older than {days} days. Sessions from the last {days} days are kept. This can't be undone.`
- Default-focused button: `Keep History`
- Destructive button: `Clear History`
- Hint: `esc keeps your history`

**Clear History failure notice** (inline, on Session History, same pattern as Summary's save-failure notice)
- `Couldn't clear history.` with a `Retry` button.

**Session Detail**
- Title: `{date}, {time}`
- Status: `{Completed/Cancelled}` shown as a badge next to the date.
- Total: same stat block as Summary — `TOTAL TIME` eyebrow, elapsed
  time, `{+/-delta} vs. 45m target` below it, for both Completed and
  Cancelled sessions.
- Per-block rows: same format as the corresponding Summary above.
- Button: `Done` — the same action and copy as Summary's, used
  consistently whether the candidate just finished a session or is
  revisiting a past one from History.

------------------------------------------------------------------------

## 11. Accessibility Behavior

- Start, Next, Skip, Cancel, the confirmation dialog's buttons, the
  `Clear History` control and its menu items, and every History row
  are reachable and operable by keyboard, with a visible focus state
  at all times.
- `BlockTimeElapsed` is announced to assistive technology via a
  polite live region (e.g. "Requirements — time's up") at the moment
  it fires, so the nudge doesn't depend on seeing the highlight or
  hearing the sound.
- The alert is never color-only: the `Time's up` text label and the
  `+overrun` countdown format carry the same meaning as the highlight,
  so a candidate who can't perceive the color change still gets it.
- No flashing or blinking effects anywhere in the alert or elsewhere
  in the experience.
- Focus is never force-moved when a new block activates — Next, Skip,
  and Cancel stay in a stable, predictable location so a keyboard or
  screen-reader user always knows where to find them.
- The Cancel confirmation traps focus while open, returns focus to
  the control that opened it on dismissal, and treats Escape the same
  as choosing "Keep going."
- The Clear History confirmation follows the identical contract: it
  traps focus while open, returns focus to the `Clear History` control
  on dismissal, and treats Escape the same as choosing `Keep History`.

------------------------------------------------------------------------

## 12. Platform & Responsive Behavior

- **macOS desktop (v1, primary)**: mouse and keyboard are the primary
  input. The window chrome (title bar, `File` / `Session` menu) frames
  the experience as shown in the high-fidelity designs. Core actions
  have keyboard shortcuts: `Space` activates `Next` while a block is
  active; `Escape` declines the Cancel confirmation (same as choosing
  `Keep going`, per §11).
- **iPhone (planned, v2/v3)**: a companion app for running the timer
  on a second device — e.g. during a whiteboard session where the Mac
  itself isn't free to hold the timer. Same capabilities, journeys,
  and behavioral contracts as macOS; touch replaces keyboard/mouse as
  the primary input, and the block countdown becomes the dominant
  on-screen element given the smaller viewport. Not in v1 scope — see
  §17.
- No other platform (Android, web, Windows/Linux desktop) is on the
  roadmap.

------------------------------------------------------------------------

## 13. Error Handling & Edge Cases

- A failed `SessionSaved` (History write fails) never blocks or hides
  the Summary screen. A small inline notice — `Couldn't save this
  session to History.` — offers `Retry`; if retry also fails, the
  notice persists but the candidate can still leave the screen.
- A failed alert sound (blocked autoplay, muted device) is not an
  error state — the visual highlight and `Time's up` label are the
  expected, sufficient fallback and nothing is surfaced to the
  candidate about it.
- Brief backgrounding (e.g. a phone call) does not count as an
  interruption — the session keeps timing normally. Interruption
  detection only runs at app launch, so only a full close/refresh
  mid-session triggers the auto-cancel behavior.
- Cancelling in the first seconds of Requirements, or a session that
  runs well past the 45m target, are not special-cased — the same
  Cancel and Complete behaviors apply regardless of how little or how
  much time has elapsed.
- A failed Clear History (I/O error) leaves History exactly as it
  was — never a partial delete — and surfaces the retriable
  `Couldn't clear history.` / `Retry` notice rather than silently
  failing or silently succeeding in the UI.
- Clearing History down to zero sessions is not an error state; it
  shows the existing empty state, unchanged.
- The count for a chosen scope is recomputed at confirm time, not
  cached from when the Clear History menu opened.

------------------------------------------------------------------------

## 14. Validation

Not applicable in v1: there is no candidate-entered form data (no
free-text notes, no custom templates, no account fields), so no
validation rules are needed at this stage.

------------------------------------------------------------------------

## 15. Decisions

``` text
Decision:
v1 supports solo practice only — no interviewer/partner mode.

Rationale:
Keeps initial scope focused on the core timing/pacing value proposition.

Status: Accepted
Stage: 5%
```

``` text
Decision:
Blocks alert when time elapses but require the candidate to manually
advance to the next block.

Rationale:
Mirrors real interviews, where a candidate often runs slightly over
on a phase. Auto-advancing would misrepresent real interview flow
and could cut a candidate off mid-thought.

Status: Accepted
Stage: 5%
```

``` text
Decision:
Session history and stats are in scope for v1.

Rationale:
Practicing pacing over time — not just once — is a core goal of the
app; trend data over multiple sessions supports that goal directly.

Status: Accepted
Stage: 5%
```

``` text
Decision:
v1 ships a single fixed default template (the six-block structure
above) with no user customization of blocks or durations.

Rationale:
Reduces initial scope; customization is deferred until the core
timer/pacing value is validated.

Status: Accepted
Stage: 5%
```

``` text
Decision:
Data Flow is included in the default template and active by default
each session. The candidate can skip it in the moment, when it
becomes the active block, rather than pre-committing before the
session starts.

Rationale:
Mirrors how real interviews decide in the moment whether to go deep
on data flow, rather than deciding before the interview begins.

Status: Accepted
Stage: 5%
```

``` text
Decision:
There is no pause/resume capability. A practice session is either
carried through to completion or cancelled; cancelling does not
preserve progress for resuming later.

Rationale:
Preserves the realism of a timed interview — real interviews don't
pause.

Status: Accepted
Stage: 5%
```

``` text
Decision:
Session success is defined at the session level — completing the
full (non-skipped) design within the overall session time budget —
not by hitting each block's individual time budget. Per-block time
is diagnostic/informational only, never pass/fail.

Rationale:
Blocks are guidance and structure, not gates. A candidate who spends
less time on one block and more on another, but completes the design
within the overall session, has succeeded.

Status: Accepted
Stage: 5%
```

``` text
Decision:
Session History records, per session: date/time, total elapsed time
vs. the session target, completion status (Completed / Cancelled),
per-block time spent vs. that block's guidance (informational), and
which blocks were skipped.

Rationale:
Reflects the session-level success model above — surfaces overall
pacing and drift patterns across blocks without judging any single
block in isolation.

Status: Accepted
Stage: 5%
```

``` text
Decision:
A session that finishes the full design past the 45m target is
still labeled "Completed," with the time delta (e.g. "+8m") shown
alongside it — there is no separate "Completed Over Time" label.

Rationale:
Finishing the design is the real win; the delta already tells the
candidate how their pacing compared to target without a second
status category to track.

Status: Accepted
Stage: 5%
```

``` text
Decision:
During an active session, both the current block's countdown and the
running total session-elapsed time are visible simultaneously.

Rationale:
The candidate needs to reason about pacing at both levels — how this
block is going, and how the overall 45m budget is tracking — to
self-correct in the moment.

Status: Accepted
Stage: 5%
```

``` text
Decision:
The time-elapsed alert is a highlight/color change on the active
block plus a single alert sound.

Rationale:
The alert's purpose is to orient and nudge the candidate, not to
interrupt or distract — a single sound plus a visual cue is enough
signal without breaking focus.

Status: Accepted
Stage: 5%
```

``` text
Decision:
An interrupted session (app closed or refreshed mid-session, with no
explicit Cancel or Completion) is auto-recorded to History as
Cancelled the next time the app opens, using whatever block progress
was reached. There is no resume.

Rationale:
Consistent with the no-pause/resume decision — an unintentional
interruption shouldn't behave differently from an intentional one,
and losing the record silently would hide a real attempt from the
candidate's history.

Status: Accepted
Stage: 50%
```

``` text
Decision:
Advancing to the next block is available at any time a block is
Active, with no minimum time enforced.

Rationale:
Direct extension of the session-level success model already accepted
at 5% — if blocks are guidance rather than gates, there's no
principled reason to force a candidate to linger on one.

Status: Accepted
Stage: 50%
```

``` text
Decision:
Cancelling requires a confirmation step that states elapsed time and
current block before committing.

Rationale:
Cancelling forfeits the session as a counted attempt, which is easy
to trigger by accident with a single tap; a lightweight confirmation
prevents losing real practice data to a mis-tap.

Status: Accepted
Stage: 50%
```

``` text
Decision:
A Skipped block is recorded distinctly from a Done block, and a
Cancelled/interrupted session's per-block breakdown always shows all
six blocks — including Not Reached for blocks the candidate never got
to — rather than a partial list.

Rationale:
Keeps the History data shape consistent across every session record,
and keeps "skipped on purpose" visually distinct from "never got
there" and from "rushed through."

Status: Accepted
Stage: 50%
```

``` text
Decision:
The time-elapsed nudge pairs a steady, non-blinking highlight with a
"Time's up" text label and a "+overrun" countdown format — never
color alone.

Rationale:
Accessibility: the cue must be perceivable without color vision and
without hearing the alert sound, and must never flash.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Next, Skip, and Cancel are debounced — a rapid repeat activation
registers once.

Rationale:
Prevents a double-tap from silently skipping two blocks or firing two
cancel attempts from a single accidental input.

Status: Accepted
Stage: 99%
```

``` text
Decision:
A failed History save never blocks or hides the Summary screen; it
surfaces a small retriable inline notice instead.

Rationale:
The candidate's immediate feedback on their own practice attempt
matters more than persistence succeeding on the first try — a save
failure shouldn't feel like the session itself failed.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Home shows a one-time, dismissible notice after an auto-cancelled
interruption is detected, rather than saving it silently in the
background.

Rationale:
Keeps the "always accounted for, never silently lost" model visible
and understandable — an unexplained Cancelled entry in History would
otherwise be confusing.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Block baselines are fixed, exact values rather than ranges:
Requirements 5m, Core Entities 5m, API / System Interface 5m, Data
Flow 5m (optional), High-Level Design 15m, Deep Dives 10m — 45m
total.

Rationale:
Surfaced by a Design Conformance Review: the high-fidelity designs
needed one real number per block, not a range, and inconsistently
guessed at one (e.g. "~15m" for High-Level Design on some screens,
"~10–15m" on others). This is now the specification. Blocks remain
baselines/guidance, not hard caps, per the session-level success
model above.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Durations and the session target are displayed as exact values,
without a "~" (approximate) prefix — "5m", "45m target," not "~5m,"
"~45m target."

Rationale:
The values are no longer fuzzy ranges, so a tilde would misrepresent
a precision that now exists. "Baseline" and "target" already carry
the "guidance, not a hard cap" meaning elsewhere in the Blueprint, so
the tilde was redundant.

Status: Accepted
Stage: 99%
```

``` text
Decision:
The session's displayed target stays at the full 45m regardless of
whether Data Flow is skipped — never recalculated to 40m for a
session that skips it.

Rationale:
The target represents the whole interview structure; skipping a
block just means finishing with more slack, not a different
goalpost. Keeps the target a stable reference so trend comparisons
across a candidate's session history stay meaningful.

Status: Accepted
Stage: 99%
```

``` text
Decision:
The skip control's copy is generic — "Skip block" — rather than
naming the block ("Skip Data Flow"), even though it currently only
ever appears while Data Flow is active.

Rationale:
Surfaced by a Design Conformance Review: the label reads cleanly in
context since the active block is already named elsewhere on screen,
and a generic label means the same string keeps working without a
copy change if a future iteration adds skipping to another block.
Corrects the Blueprint, which had specified "Skip Data Flow" — the
design's choice stands.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Home shows a template preview — all six blocks with their durations,
under a "TEMPLATE · 6 BLOCKS · 45M" eyebrow — before the candidate
starts a session. It's informational only, not a way to jump into or
reorder a block.

Rationale:
Surfaced by a Design Conformance Review: the design already shows
this, and it gives the candidate a clear preview of what they're
about to practice — a real gap in the original Blueprint, not a
design overreach. Corrects the Blueprint; the design's choice stands.

Status: Accepted
Stage: 99%
```

``` text
Decision:
The segmented block-progress bar (time spent / skipped / not
reached) is an accepted, recurring UI device across Active session,
Time's Up, Summary, Session History, and Session Detail — not
decorative, an at-a-glance encoding of a session's shape.

Rationale:
Surfaced by a Design Conformance Review: the design already uses this
pattern consistently across five screens, and it carries real
information the Blueprint had never captured. Corrects the Blueprint;
the design's choice stands.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Delta-vs-target is always shown — for Completed and Cancelled
sessions alike — on History rows, Summary, and Detail. It is never
omitted for a Cancelled session.

Rationale:
Surfaced by a Design Conformance Review: the current designs drop the
delta on Cancelled rows/Detail, but a cancelled session still has a
meaningful "how far under target was I when I stopped" data point,
and keeping delta consistent across every session keeps History
comparable regardless of outcome. This confirms the Blueprint's
original copy templates; the designs need a follow-up update to add
delta back to their Cancelled variants.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Per-block and total-time copy follows the design's structural
pattern — a stat block for totals (eyebrow, big figure, delta below)
and two-column rows for blocks, with a `SKIPPED` badge — rather than
the Blueprint's original single-sentence templates ("Total time: …",
"{Block} — {time} (baseline …)", "Data Flow — Skipped").

Rationale:
Surfaced by a Design Conformance Review: the design already renders
this way consistently, and it reads better as a scannable summary
than as prose. Corrects the Blueprint's copy templates to match; the
design's structure stands. The underlying data shown is unchanged —
this only affects presentation shape, not content.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Session Detail's primary action is `Done` — the same copy and
behavior as Summary's — used consistently whether the candidate just
finished a session or is revisiting a past one from History.

Rationale:
Surfaced by a Design Conformance Review: the Blueprint had never
defined an action for Detail at all. Reusing `Done` keeps the
end-of-session and browse-history experiences consistent rather than
introducing a second verb for what is functionally the same "I'm
finished looking at this" action.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Three strings the designs already used consistently are now captured
in Copy: the `BLOCK {n} OF 6` / `SESSION {elapsed}` header pair and
the `baseline {baseline} · of 45m budget` line on active-session
screens, and Summary — Completed's outcome subline ("All six blocks
carried through[, one skipped by choice].").

Rationale:
Surfaced by a second Design Conformance Review pass: these were gaps
in the Blueprint's documentation, not deviations by the design — all
three appeared consistently across both themes and (for the header
pair) across two screens, but were never written down. Corrects the
Blueprint to match what was already built.

Status: Accepted
Stage: 99%
```

``` text
Decision:
v1 ships as a native macOS desktop app. iPhone is planned for v2/v3
as a companion device, not a replacement — same capabilities and
behavioral contracts, touch-first instead of keyboard/mouse-first.
No other platform (Android, web, Windows/Linux) is on the roadmap.
Keyboard shortcuts are part of v1: Space activates Next, Escape
declines the Cancel confirmation.

Rationale:
Surfaced while starting technical planning: the high-fidelity designs'
OS chrome (title bar, File/Session menu) turned out to be literal, not
a presentation frame, which the Blueprint's prior "mobile is primary"
framing contradicted. Since both planned platforms are Apple's, the
Blueprint records the platform roadmap itself (not implementation
technology) because it changes real behavior — primary input method,
which device the candidate is expected to have in front of them, and
what "responsive" means for this app.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Skipping Data Flow keeps whatever time had elapsed on it before the
skip, instead of discarding it. It's still not counted as an attempt
against the block's baseline — no "· 5m" comparison, no SKIPPED-badge
grading — but the Summary/Detail breakdown shows it as "{time} before
skipping" next to the badge.

Rationale:
Surfaced during real use: session totals and their per-block
breakdowns were silently a few seconds apart whenever Data Flow was
skipped after any time had passed on it, since that time still ticks
into the session-level clock but had nowhere to show up per-block.
Mathematically correct, but it read as a bug and eroded trust in the
app's arithmetic. Showing the time (without grading it) fixes the
optics without reopening the actual "not an attempt" rule.

Status: Accepted
Stage: 99%
```

``` text
Decision:
"Clear older than X days" removes sessions OLDER than X days (a
retention/prune model) — not sessions FROM the last X days (a
recency-wipe model, the browser-history convention).

Rationale:
The trigger is accumulation, not privacy. A candidate practicing over
weeks/months wants to drop old test/throwaway sessions while keeping
recent ones for pacing trend comparisons — the opposite of what a
recency wipe would do.

Status: Accepted
Stage: 99%
```

``` text
Decision:
v1 ships both "Clear All" and a day-range prune option — not Clear
All alone.

Rationale:
Clear All is a blunt instrument for an app whose stated value is
trend data over time. A candidate who wants to drop a burst of
accumulated/throwaway sessions but keep the meaningful history has no
way to do that with Clear All alone.

Status: Accepted
Stage: 99%
```

``` text
Decision:
Day-range presets are fixed at 30 and 90 days — no free-typed number.

Rationale:
Confirmed by the candidate — reasonable defaults for how often
practice happens; consistent with v1's "no candidate-entered form
data" posture.

Status: Accepted
Stage: 99%
```

``` text
Decision:
"All Time" uses the same single-confirm pattern as the day-range
scopes — no extra step (e.g. typing "DELETE"), even though it's the
one scope that can erase the entire history in one action.

Rationale:
Confirmed by the candidate. Keeps the confirmation UX uniform across
all three scopes and consistent with the existing Cancel Session
confirmation's single-step pattern — the named count + "can't be
undone" wording is the safeguard, not extra friction.

Status: Accepted
Stage: 99%
```

------------------------------------------------------------------------

## 16. Open Questions

None at this time.

------------------------------------------------------------------------

## 17. Deferred Items

``` text
Deferred:
Partner / interviewer mode.

Reason:
Out of scope for v1 per the solo-practice decision above; may be
revisited once solo practice is validated.
```

``` text
Deferred:
Customizable templates (block order, durations, multiple templates).

Reason:
v1 ships one fixed default template only.
```

``` text
Deferred:
iPhone companion app.

Reason:
Planned for v2/v3, not v1. Same capabilities and behavioral
contracts as macOS; deferred so v1 can ship as a focused, native
macOS app first.
```

``` text
Deferred:
Multi-user accounts / authentication.

Reason:
Not yet raised; implicitly out of scope until needed for history
persistence design.
```

``` text
Deferred:
Export or backup of History before a destructive clear (e.g. a JSON
export prompt).

Reason:
Confirmed by the candidate — not needed at this time. Would expand
scope beyond the accumulated-history problem Clear History solves.
Worth reconsidering if data loss from the feature turns out to be a
real regret in practice.
```

``` text
Deferred:
Undo / soft-delete (trash) window after a Clear History action.

Reason:
Adds real complexity (retention of "deleted" records, a second
cleanup job) for a feature whose whole purpose is disk/list hygiene.
The confirmation's explicit count + "can't be undone" wording is the
chosen safeguard instead.
```

------------------------------------------------------------------------

## 18. Resolution / Stage

**Current stage:** 99% — Refinement (Design Conformance Review complete)

**Since the initial 99% draft:** the high-fidelity designs
(`docs/designs`) were checked against this Blueprint. Eight
gaps surfaced; all eight are now resolved and recorded as decisions
above — most confirmed the design's choices and corrected the
Blueprint's copy/rules to match, one (delta shown for Cancelled
sessions) confirmed the Blueprint and flags a follow-up fix needed in
the designs themselves.

**Outstanding, outside the Blueprint:** the Cancelled-session designs
(History rows, Detail, and any Cancelled Summary screen) still need
delta added next to their totals to match the decision above.

**Next milestone:** regenerate the User Journey Map view (held per
request until this refinement pass closed out), then the Blueprint is
ready for implementation, with Conformance Review checking the built
app against the Behavioral Contracts in §8.

**Since then — Clear Session History folded in:** the accepted diff
`docs/blueprint-diffs/clear-session-history.md` has been merged into
this Blueprint — new capability (§3), journeys (§5), rules (§7),
behavioral contracts (§8), the `HistoryCleared` event (§9), copy
(§10), accessibility (§11), error handling (§13), decisions (§15),
and deferred items (§17). The feature is implemented on branch
`feat/clear-session-history`, with the build itself recorded in
`docs/architecture.md` (Phase 7). The diff's own journey view has
since been merged into the single current map at
`docs/views/user-journey map.html`.
