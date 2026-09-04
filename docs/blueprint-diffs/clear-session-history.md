# Blueprint Diff: Clear Session History

**Diffed against:** `docs/application-blueprint.md`, rev. 13 (99% —
Refinement)\
**Status:** Accepted and folded into `application-blueprint.md`
(§3, §5, §7, §8, §9, §10, §11, §13, §15, §17, §18), with the build
itself recorded in `docs/architecture.md` (Phase 7). Implemented on
branch `feat/clear-session-history`. This file is retained as the
change record; its own journey view has since been merged into the
main map (§15 below).\
**Prompted by:** real use — sessions have been accumulating in History
with no way to prune them.

------------------------------------------------------------------------

## 0. Framing decisions (resolved during scoping)

Two forks had to be settled before this diff could be written; both
were put to the candidate (the app's only stakeholder in v1) rather
than assumed:

``` text
Decision:
"Clear past X days" removes sessions OLDER than X days (a retention/
prune model) — not sessions FROM the last X days (a recency-wipe
model, the browser-history convention).

Rationale:
The trigger is accumulation, not privacy. A candidate practicing over
weeks/months wants to drop old test/throwaway sessions while keeping
recent ones for pacing trend comparisons — the opposite of what a
recency wipe would do.

Status: Proposed
```

``` text
Decision:
v1 ships both "Clear All" and a day-range prune option — not Clear
All alone.

Rationale:
Clear All is a blunt instrument for an app whose stated value is
trend data over time (Blueprint §15: "Session history and stats are
in scope for v1... practicing pacing over time is a core goal"). A
candidate who wants to drop a burst of accumulated/throwaway sessions
but keep the meaningful history has no way to do that with Clear All
alone.

Status: Accepted
```

``` text
Decision:
Day-range presets are fixed at 30 and 90 days.

Rationale:
Confirmed by the candidate — reasonable defaults for how often
practice happens; no need for a free-typed number (Blueprint §14
posture: no candidate-entered form data in v1).

Status: Accepted
```

``` text
Decision:
"All Time" uses the same single-confirm pattern as the day-range
scopes — no extra step (e.g. typing "DELETE") even though it's the
one scope that can erase the entire history in one action.

Rationale:
Confirmed by the candidate. Keeps the confirmation UX uniform across
all three scopes and consistent with the existing Cancel Session
confirmation's single-step pattern (Blueprint §7) — the named count +
"can't be undone" wording is the safeguard, not extra friction.

Status: Accepted
```

------------------------------------------------------------------------

## 1. Capability

``` text
+ Clear Session History
```

Added to Blueprint §3 (Capabilities), alongside the existing `View
Session History` and `Review a Past Session's Detail`.

------------------------------------------------------------------------

## 2. Entry Points

``` text
No change.
```

Reachable from the existing **Session History** entry point — no new
top-level entry point is introduced.

------------------------------------------------------------------------

## 3. Journeys

**New — clear history:**

``` text
Session History
  ↓
Clear History (menu)
  ↓
Older than 30 days | Older than 90 days | All Time
  ↓
Confirm
  ↓
Session History (updated / empty state)
```

**Alternate — decline:**

``` text
Session History → Clear History → choose scope → Keep History (or Escape)
  → Session History, unchanged
```

Both are extensions of the existing `Session History → Select Session
→ Session Detail` journey group in Blueprint §5, not a new top-level
journey.

------------------------------------------------------------------------

## 4. Actions

``` text
+ Open Clear History menu
+ Choose Clear Scope (Older than 30 days / Older than 90 days / All Time)
+ Confirm Clear History
+ Decline Clear History
```

------------------------------------------------------------------------

## 5. States

``` text
No change to Session or Block states.
```

Clearing acts on the History *collection*, not on any individual
`Session`'s state machine — a cleared session is removed outright, not
transitioned to some new status.

------------------------------------------------------------------------

## 6. Rules and Constraints (additions to Blueprint §7)

- Clear History acts only on saved History records
  (`JSONFileSessionStore`'s `sessions.json`). It never touches an
  in-progress session or the abandoned-session marker used for
  Interruption detection (Blueprint §8/§13) — those are a separate
  store, untouched by this feature.
- The `Clear History` control is hidden when History is empty —
  nothing to clear, so no dead-end control is shown.
- A day-range option that currently matches zero sessions is omitted
  from the menu rather than shown disabled — a candidate is never
  offered a scope that would be a confirmed no-op.
- Each scope shown in the menu carries the count of sessions it would
  remove, so the candidate sees the size of the action before opening
  the confirmation.
- The confirmation always names the exact number of sessions that
  scope will remove, and states plainly that the action can't be
  undone.
- The confirmation's default-focused choice is always the
  non-destructive one (`Keep History`), and its destructive button is
  spatially/visually distinct — the same precedent as the existing
  Cancel Session confirmation (Blueprint §7: "the cancel confirmation
  defaults to the non-destructive choice, so a mis-tap can't discard a
  real attempt"). Here the stakes are higher (multiple sessions, not
  one), so the same defensive pattern applies at minimum.
- Rapid repeated activation of the destructive confirm button
  registers once — same debounce rule already applied to Next, Skip,
  and Cancel (Blueprint §7).
- If the one-time interruption notice (Blueprint §10: "Your last
  session ended unexpectedly...") is still showing and its linked
  session gets removed by a clear action, the notice — if still
  visible — drops its `View` link rather than pointing at a session
  that no longer exists. The dismissible text itself is unaffected.
- Day-range thresholds are fixed presets (30 / 90 days), not a
  free-typed number — consistent with v1's existing "no
  candidate-entered form data" posture (Blueprint §14). Flagged as
  adjustable; not a hard requirement of this diff.

------------------------------------------------------------------------

## 7. Behavioral Contracts (additions to Blueprint §8)

``` text
Action:
Open Clear History Menu

Expected behavior:
- Available only when Session History has at least one saved session.
- List up to three scopes — "Older than 30 days", "Older than 90
  days", "All Time" — omitting any day-range scope that currently
  matches zero sessions. "All Time" is always present whenever the
  control is shown.
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
  all sessions (All Time), or every session whose `startedAt` is
  older than (now − N days) for the chosen N.
- Sessions with `startedAt` inside the retained window (or all
  sessions, for a day-range scope) are left untouched.
- Any session currently In Progress, and the abandoned-session marker,
  are unaffected regardless of scope.
- If the interruption notice's linked session was just removed, drop
  its `View` link (Blueprint §13's notice itself stays if still
  otherwise eligible to show).
- Return to the Session History list — showing the empty state
  (Blueprint §10) if that was the last session removed.
- Emit HistoryCleared(scope, sessionsRemoved).
- If the underlying delete fails (e.g. disk I/O error), History is
  left exactly as it was before the attempt — never partially
  cleared — and a small retriable inline notice is shown, the same
  pattern as a failed SessionSaved (Blueprint §8, §13): "Couldn't
  clear history." with `Retry`.
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

## 8. Events (additions to Blueprint §9)

- **HistoryCleared** `{ scope, sessionsRemoved }` — a clear action
  completed. `scope` is `.allTime` or `.olderThan(days: Int)`.

------------------------------------------------------------------------

## 9. Copy (additions to Blueprint §10)

**Session History**
- New control, header row, grouped with `Done` at the trailing edge:
  `Clear History` (opens a menu) — hidden when the list is empty. It
  opens a menu rather than acting immediately, so it does not need the
  spatial separation the Cancel Session control keeps from Next; sitting
  next to `Done` is fine.
- Menu items, each with the count of sessions that scope would remove,
  right-aligned: `Older than 30 days`, `Older than 90 days`, `All Time`
  — omitting any day-range item with zero matching sessions.

**Clear History confirmation**
- Title: `Clear {N} session{s}?`
- Body — All Time: `This permanently deletes your entire session
  history — {N} sessions. This can't be undone.`
- Body — day range: `This permanently deletes {N} sessions older than
  {days} days. Sessions from the last {days} days are kept. This
  can't be undone.`
- Default-focused button: `Keep History`
- Destructive button: `Clear History`
- Hint: `esc keeps your history`

**Failure notice** (inline, on Session History, same pattern as
Summary's save-failure notice)
- `Couldn't clear history.` with a `Retry` button.

------------------------------------------------------------------------

## 10. Accessibility (additions to Blueprint §11)

- The `Clear History` control, its menu items, and the confirmation's
  buttons are reachable and operable by keyboard, with a visible focus
  state — same standard already applied to Start/Next/Skip/Cancel and
  every History row.
- The Clear History confirmation traps focus while open, returns focus
  to the control that opened it on dismissal, and treats Escape the
  same as choosing `Keep History` — identical contract to the existing
  Cancel confirmation (Blueprint §11).

------------------------------------------------------------------------

## 11. Error Handling & Edge Cases (additions to Blueprint §13)

- A failed clear (I/O error) leaves History exactly as it was —
  never a partial delete — and surfaces the retriable inline notice
  above rather than silently failing or silently succeeding in the UI.
- Clearing down to zero sessions is not an error state; it shows the
  existing empty state (Blueprint §10), unchanged.
- If new sessions are saved between opening the Clear History menu and
  confirming (not possible today — History can only be viewed while no
  session is in progress — but recorded here as a boundary), the
  scope's count is recomputed at confirm time, not cached from when
  the menu opened.

------------------------------------------------------------------------

## 12. Impact Summary

``` text
Capabilities:  +1  (Clear Session History)
Actions:       +4  (Open menu, choose scope, confirm, decline)
Events:        +1  (HistoryCleared)
Screens:        1  changed (Session History — new control + confirmation)
Screens:        0  added
States:         0  changed (History is a collection, not a state machine)
Store surface: +1  method on SessionStore (clear by scope)
```

------------------------------------------------------------------------

## 13. Open Questions

``` text
None at this time.
```

Both questions raised in the original draft (day-range presets;
whether "All Time" needs a stronger confirmation) were resolved by the
candidate and are now recorded as Accepted decisions in §0.

------------------------------------------------------------------------

## 14. Deferred Items (additions to Blueprint §17)

``` text
Deferred:
Export or backup of History before a destructive clear (e.g. a JSON
export prompt).

Reason:
Confirmed by the candidate — not needed at this time. Not asked for,
and would expand this diff's scope beyond the accumulated-history
problem it's solving. Worth reconsidering if data loss from this
feature turns out to be a real regret in practice.
```

``` text
Deferred:
Undo / soft-delete (trash) window after a clear.

Reason:
Adds real complexity (retention of "deleted" records, a second cleanup
job) for a v1 feature whose whole purpose is disk/list hygiene. The
confirmation's explicit count + "can't be undone" wording is the
chosen safeguard instead.
```

------------------------------------------------------------------------

## 15. Views

- **User Journey Map:** [`docs/views/user-journey map.html`](../views/user-journey%20map.html)
  — this diff's clear-history flow (menu → scope → confirm → outcome,
  including the failed-delete retry path) plus the one edge case it
  touches (the abandoned-session interruption notice losing its
  `View` link if the linked session is cleared), folded into the
  single current Blueprint journey map (SVG) alongside the unchanged
  practice-session/cancel/interruption flow. A projection of the
  Blueprint, not an independent source of truth — regenerate it if
  the journey changes rather than hand-editing it. (An earlier
  diff-scoped Mermaid version of this view, and a separate
  pre-Phase-7 map, both existed briefly and have since been
  consolidated into this one file.)

------------------------------------------------------------------------

## 16. Next Step

All decisions in this diff are Accepted and no Open Questions remain.
Per `application-blueprint-spec-v0.1.md` §8, its contents are ready to
fold into `application-blueprint.md` as new/amended §3, §7, §8, §9,
§10, §11, §13 entries. Implementation can then proceed against
`SessionStore` (`Sources/TimerCore/Persistence/`) and
`SessionHistoryView` (`Sources/TimerMac/Views/`) — not started yet;
say the word when you want that folded in and/or built.
