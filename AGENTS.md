# AGENTS.md — Fortnite FPS Tracker

Instructions for any AI agent working in this folder.

## Purpose

Tune Fortnite (PC, Battle Royale) for maximum sustained frame rate and minimum stutter,
without hurting the ability to see and track enemies. The user already runs
**Performance Mode (Alpha)** and has done some OS-level tweaking.

## Read order

1. `README.md` — context and status
2. `01-current-settings.md` — what is currently set
3. `02-tweak-backlog.md` — what to try next
4. `03-test-protocol.md` — how to measure
5. `04-tweak-log.md` + `benchmarks.csv` — what has already been tried and what it did

## Conventions

- `04-tweak-log.md` is **append-only**. Never rewrite or delete past entries, even wrong ones.
  A tweak that did nothing is a useful result.
- Every change needs a before row and an after row in `benchmarks.csv`, same scenario.
- `benchmarks.csv` schema (do not reorder columns):
  `date,scenario,change_id,setting,value,avg_fps,low_1pct,max_fps,gpu_util_pct,cpu_util_pct,notes`
- `change_id` links a `benchmarks.csv` row to its `04-tweak-log.md` entry. Format: `T-001`, `T-002`, ...
- When updating `01-current-settings.md`, change the Status column only after the tweak is
  verified in `04-tweak-log.md`. That file describes reality, not intentions.
- Tag every recommendation with confidence: `[high]`, `[medium]`, `[low]`. Fortnite's settings
  menu changes between chapters and seasons, so anything older than the current season is `[low]`
  until confirmed in-game.

## Hard constraints

- **Never** recommend, download, or run third-party tools that inject into or modify the running
  Fortnite process. Easy Anti-Cheat and BattlEye ban for this. Config file edits and Windows
  settings are fine.
- **Do not** modify anything under `%LOCALAPPDATA%\FortniteGame\Saved\Config\WindowsClient\`
  without first backing up the file into `backups/` in this folder and logging it as a change.
- Do not mark a config file read-only as a "fix". It causes settings corruption and silent resets.
- Do not suggest lowering 3D Resolution below 100% as a default. It blurs enemy models and the
  user cares about tracking targets, not just the FPS counter.
- Do not cite undated blog posts as evidence. Prefer Epic's own docs, or dated benchmarks.

## Before recommending hardware-specific settings

The GPU, CPU, RAM, resolution and monitor refresh rate are all still unknown (see README).
Ask the user rather than assuming a rig tier. Advice for a 240Hz high-end build and a
CPU-bound laptop are close to opposites.

## Diagnostic shortcut

To tell whether the user is CPU-bound or GPU-bound: drop 3D Resolution to 50% for one test run.
If FPS barely moves, the bottleneck is the CPU — in that case shadows, textures and resolution
changes are wasted effort, and the wins are replays off, background processes, view distance,
and player-count-heavy end-game scenarios.
