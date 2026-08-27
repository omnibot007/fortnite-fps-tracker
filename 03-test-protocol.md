# 03 — Test protocol

If a number was not collected this way, it does not go in `benchmarks.csv`.

## Why this matters

Fortnite FPS swings wildly by POI, player count, storm phase and time of day. Two runs measured
differently can differ by 40+ FPS with no setting changed at all. Without a fixed scenario, every
result in this folder is noise.

## Setup, once

1. Video settings > **Show FPS: On**.
2. Close browsers, overlays, launchers, and anything with a capture or chat overlay.
3. Let the machine sit at desktop idle for 2 minutes before the first run — a cold rig scores
   higher than a warm one, especially on a laptop, and that difference will be misread as a win.
4. Same power plan and same charger state every time. Battery vs plugged in is not comparable.

## Standard scenarios

Run **both**. They stress different bottlenecks.

### Scenario A — "open field" (GPU-leaning)
- Creative or a private/solo match, land at the same fixed POI every time.
- Stand still 15s facing a fixed landmark, then run a fixed loop for 60s.
- Records: avg FPS, 1% low, max.

### Scenario B — "build fight" (CPU-leaning)
- Same location, 60s of continuous building, editing and turbo-building.
- This is where stutter shows up and where replays, background processes and CPU limits bite.
- Records: avg FPS, 1% low, and a subjective stutter note (`none` / `mild` / `bad`).

A setting that helps A but not B on a CPU-bound rig is not a real win.

## Per-test procedure

1. Change **exactly one** setting.
2. Restart the game if the setting touches the renderer. Some do not fully apply until restart.
3. Play one throwaway match first — DX12-based modes compile shaders and the first 2-3 matches
   after any renderer change or game patch are artificially stuttery. Do not measure those.
4. Run Scenario A, then Scenario B.
5. Record both rows in `benchmarks.csv` with the same `change_id`.
6. Write the entry in `04-tweak-log.md` including the verdict: `keep`, `revert`, or `inconclusive`.

## Reading the results

- **1% lows matter more than average.** A tweak that adds 15 to the average but tanks the 1% low
  feels worse to play. Judge by the low.
- Anything under a ~3% change is noise. Do not chase it.
- If the frame counter is high but the game still feels bad, the problem is frametime consistency
  or latency, not FPS. Look at stutter notes and V-Sync / Reflex, not quality sliders.

## After every Fortnite patch

Re-run the baseline. Patches reset settings, change renderer behaviour, and invalidate old
numbers. Log the game version in the `notes` column so stale rows are identifiable later.
