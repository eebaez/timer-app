# 45-Minute Spec Handoff

**For:** Product Designer\
**Re:** Text/value updates needed in `docs/artifacts/designs`\
**Source of truth:** `docs/application-blueprint.md` — §7 (durations), §10 (copy), §15 (decisions)

The Blueprint's block durations and session target changed during
refinement. The mockups were built against the old numbers, so most
screens need a text update — **no layout or component changes are
implied by anything below, text and numbers only.**

------------------------------------------------------------------------

## What changed, in one line each

- **Session target: 60m → 45m.** Core Entities went from ~2m to a flat
  5m, and High-Level Design's ~10–15m range became a flat 15m. New
  total: 5 + 5 + 5 + 5 + 15 + 10 = **45m**.
- **No more "~".** Durations and the target now display as exact
  values — `5m`, `45m target` — not `~5m`, `~45m target`.
- **Cancelled sessions now show a delta too.** Previously only
  Completed sessions showed "+/- vs. target"; Cancelled ones showed
  just the elapsed time. Now every session shows a delta, regardless
  of how it ended.

------------------------------------------------------------------------

## Home

*Files: `01-home.png` (light + dark)*

| Before | After |
|---|---|
| `TEMPLATE · 6 BLOCKS · ~60M` | `TEMPLATE · 6 BLOCKS · 45M` |
| Core Entities · `~2m` | Core Entities · `5m` |
| High-Level Design · `~10–15m` | High-Level Design · `15m` |
| Requirements / API / Data Flow · `~5m` | `5m` (drop the "~") |
| Deep Dives · `~10m` | Deep Dives · `10m` |

------------------------------------------------------------------------

## Active Block

*Files: `02-active-block.png` (light + dark) — Data Flow 04:12 example*

| Before | After |
|---|---|
| `baseline ~5m · of ~60m budget` | `baseline 5m · of 45m budget` |

------------------------------------------------------------------------

## Time's Up

*Files: `03-times-up.png` (light + dark) — High-Level Design +0:45 example*

| Before | After |
|---|---|
| `baseline ~15m · of ~60m budget` | `baseline 15m · of 45m budget` |

Value was already right — this one's just dropping the "~" and fixing
the budget number.

------------------------------------------------------------------------

## Cancel Confirmation

*Files: `04-cancel-confirmation.png` (light + dark)*

No changes — nothing on this screen references a duration or target.

------------------------------------------------------------------------

## Summary — Completed

*Files: `05-summary-completed.png` (light + dark) — 58:20 example*

| Before | After |
|---|---|
| Core Entities · `~2m` | Core Entities · `5m` |
| Other baselines · `~5m` / `~15m` / `~10m` | Drop the "~" on all of them |
| `58:20 · −1:40 vs. ~60m target` | `58:20 · +13:20 vs. 45m target` |

**Heads up:** against a 45m target, 58:20 is now 13:20 *over*, not 1:40
under — the delta doesn't just relabel, it flips sign. Might be worth
picking a new example total that demonstrates finishing under the new
45m target instead.

------------------------------------------------------------------------

## Session History

*Files: `06-session-history.png` (light + dark) — 3 example rows*

| Row | Before | After |
|---|---|---|
| Aug 24 · Completed | `58:20 (−1:40)` | `58:20 (+13:20)` |
| Aug 22 · Cancelled | `21:05` *(no delta)* | `21:05 (−23:55)` |
| Aug 21 · Completed | `68:00 (+8:00)` | `68:00 (+23:00)` |

The Cancelled row is the one structural addition here — it needs a
delta shown for the first time, same as the Completed rows.

------------------------------------------------------------------------

## Session Detail

*Files: `07-session-detail.png` (light + dark) — Aug 22, Cancelled, 21:05 example*

| Before | After |
|---|---|
| `21:05 · of ~60m target` *(no delta)* | `21:05 · −23:55 vs. 45m target` |
| Core Entities · `~2m` | Core Entities · `5m` |
| Requirements / API · `~5m` | `5m` (drop the "~") |

If there's a Cancelled Summary screen beyond this set (shown right
after ending a session, before History), it needs the same delta
treatment.
