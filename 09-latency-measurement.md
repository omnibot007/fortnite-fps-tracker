# 09 — Measuring input lag on this machine

Created: 2026-08-13

This file exists because for most of this project we had no way to measure input lag, which meant
every latency item in the backlog was theory. That is now solved, and it turned out to require no
new software at all.

**Correction to earlier advice in this project:** it was previously stated that measuring input lag
here would need an NVIDIA LDAT or a Reflex-capable monitor. That was wrong.

---

## The instrument: PresentMon 2.3.1

Already on this machine, bundled inside RivaTuner Statistics Server 7.3.7:

```
C:\Program Files (x86)\RivaTuner Statistics Server\Plugins\Client\PresentMonDataProvider\PresentMon-2.3.1-x64.exe
```

Also present: `PresentMon-2.3.1-x64-DLSS4.exe`, `PresentMon-1.10.0-x64.exe`, and RTSS overlay
layouts `presentmon_latency_analyzer.ovl` and `reflex.ovl`.

**Why this one and not an overlay tool.** PresentMon consumes **ETW** (Event Tracing for Windows).
It runs out of process and never injects into the game. That is what makes it appropriate to run
alongside Easy Anti-Cheat. Ground rule 3 in the README bans injecting FPS utilities — PresentMon
does not violate it. RTSS's own on-screen overlay *does* inject, and is a separate decision (see
below); this machine already has an RTSS profile for Fortnite, so that choice was made previously.

Requires an **elevated** shell. Verified working here on 2026-08-13: a 10-second capture returned
841 frames.

---

## What it actually reports

Confirmed CSV columns from a live capture on this machine:

| Column | Meaning |
| --- | --- |
| `MsClickToPhotonLatency` | **Mouse click → photons on screen.** The number people mean by "input lag". |
| `MsAllInputToPhotonLatency` | Any input (key or mouse) → photons. Larger sample than click-only. |
| `MsPCLatency` | Reflex-reported PC latency. Only populated when the game drives Reflex markers. |
| `MsRenderPresentLatency` | Render submit → present. The render-side slice. |
| `MsUntilDisplayed` | Present → actually scanned out. Where compositor and refresh delay show up. |
| `MsBetweenPresents` | Frametime. Source of average FPS and 1% lows. |
| `MsGPUBusy` / `MsCPUBusy` | Which side is saturated. This settles **T-004** without guesswork. |
| `PresentMode` | Composition path. See below — this is the **T-007** evidence. |
| `SyncInterval` / `AllowsTearing` | Whether V-Sync or tearing is actually in effect, as opposed to what the menu claims. |

### PresentMode is the sleeper feature

- `Composed: Flip` — the **desktop compositor (DWM) is in the frame path**. This is what windowed
  and borderless modes do, and it costs up to one full refresh: **16.7 ms on this 60 Hz panel**.
- `Hardware: Independent Flip` — compositor bypassed. This is the low-latency path.
- `Hardware: Legacy Flip` — also bypassed, older path.

`GameUserSettings.ini` currently reports `FullscreenMode=2` (windowed) at 923×915. If a capture
confirms `Composed: Flip`, that is direct, measured proof of T-007 rather than an inference from a
config file — and it is the single largest latency item available on this setup.

---

## How to run it

Use the harness in this folder. From an **elevated** PowerShell:

```powershell
cd C:\Users\LENOVO\fortnite-fps-tracker
.\measure.ps1 -Seconds 60 -ChangeId T-001 -Scenario A -Label baseline
```

It counts down 8 seconds so you can alt-tab into the game, records, then prints average FPS, 1% and
0.1% lows, latency percentiles, the present-path breakdown, a CPU-vs-GPU-bound verdict, and a
ready-to-paste `benchmarks.csv` row. Raw per-frame CSVs land in `measurements/`.

Raw equivalent, if you want to drive it by hand:

```powershell
& 'C:\Program Files (x86)\RivaTuner Statistics Server\Plugins\Client\PresentMonDataProvider\PresentMon-2.3.1-x64.exe' `
  --process_name FortniteClient-Win64-Shipping.exe `
  --output_file C:\Users\LENOVO\fortnite-fps-tracker\measurements\run.csv `
  --timed 60 --terminate_after_timed --stop_existing_session
```

Input tracking is **on by default**; `--no_track_input` would disable it. Do not pass that.

### The one way this fails

**Fortnite must be in the foreground and actively rendering.** A minimized Fortnite presents zero
frames and PresentMon writes no CSV at all — this was hit on the first attempt on 2026-08-13, when
the game was running but minimized and the only presenting apps on the whole system were
`Notion.exe` and `dwm.exe`. "No CSV produced" means "nothing was rendering", not "the tool broke".

---

## Live on-screen readout (optional)

The RTSS profile `Profiles\FortniteClient-Win64-Shipping.exe.cfg` already exists and already has
`ReflexGetLatency = 1` and `ReflexSetLatencyMarker = 1`, so RTSS is configured to read Reflex
latency markers. What it does **not** have is statistics collection — `EnableStat`,
`PercentileCalc`, `FrametimeCalc` and `PeakFramerateCalc` are all `0`, so it cannot currently show
1% lows. Turning those on plus loading the `presentmon_latency_analyzer.ovl` overlay gives a live
number on screen.

Use this for *feel* and for spotting problems mid-match. Use PresentMon CSV for anything that goes
in `benchmarks.csv`. Note that RTSS's overlay injects into the game, unlike PresentMon.

---

## Absolute cross-check (optional, once)

PresentMon measures from the OS input event onward. It cannot see the mouse's own sensor-to-USB
delay or the panel's response time, so its click-to-photon is a **lower bound** on true
end-to-end lag.

For a one-time absolute number: film the screen and the mouse together at 240 fps slo-mo on a
phone, count frames between the click and the muzzle flash, multiply by 4.17 ms. Compare against
PresentMon to learn this machine's fixed offset, then trust PresentMon for all A/B work.

---

## Protocol rules

These matter more than the tool.

1. **60 seconds minimum** per run, same scenario each time — Scenario A open field, Scenario B
   build fight, per `03-test-protocol.md`.
2. **A/B/A, always.** Latency and framerate both drift. The NA-West ping floor moved 22 → 30 ms
   inside 25 minutes on 2026-08-13; frametimes drift with GPU temperature on a 50 W-capped Quadro
   in a workstation chassis. A single A-then-B comparison will mislead you.
3. **Judge by 1% lows and by the p99 of click-to-photon**, not by averages. Averages hide exactly
   the stutter that gets you killed.
4. **Under 3% is noise.** FrameSync Labs uses a stricter 4% bar off 20 passes; we have far fewer
   passes, so treat anything under 3% as nothing.
5. **Discard the first 2–3 matches** after a renderer change or a game patch — shader cache is
   rebuilding and the numbers are garbage.
6. One change per test.

---

## What to measure first

1. **T-001 baseline.** Nothing else is interpretable without it.
2. **T-007 fullscreen 1920×1080.** Expect `PresentMode` to flip from `Composed: Flip` to
   `Hardware: Independent Flip` and click-to-photon to drop by up to ~16.7 ms. Biggest single item.
3. **T-006 frame cap 60–70.** Watch whether `MsGPUBusy` stops pinning the frametime; a GPU held at
   100% queues frames and adds latency.
4. **T-004 CPU vs GPU bound** — free, since `MsCPUBusy` / `MsGPUBusy` come with every capture.
5. **T-009 Reflex On vs On+Boost**, which the two corpora disagree about. Now settleable locally.
