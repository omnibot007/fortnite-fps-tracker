# Fortnite FPS Tracker

Owner: entitykoo
Created: 2026-08-13
Machine: Lenovo ThinkPad P15 Gen 1 (20SUS34900) — i7-10750H / Quadro T1000 4GB / 32GB / 1080p 60Hz
Rendering mode in use: **Performance Mode (Alpha)**

## What this is

A working folder for squeezing frames out of Fortnite. The focus is in-game settings and system
configuration — specifically cutting animation, VFX and effect load, plus the CPU and thermal costs
that Performance Mode does not remove on its own.

## Folder map

| File | Purpose |
| --- | --- |
| `AGENTS.md` | Instructions and hard constraints for any AI agent working in this folder. Read first. |
| `01-current-settings.md` | The known-good baseline config. Source of truth for "what is set right now". |
| `02-tweak-backlog.md` | Ranked list of remaining levers, with expected gain, effort and confidence. |
| `03-test-protocol.md` | How to benchmark so results are comparable. Read before recording any number. |
| `04-tweak-log.md` | Append-only chronological log of every change and its outcome. |
| `05-hardware.md` | Measured hardware and system state, and what it implies. **Read before advising.** |
| `06-network.md` | Measured latency path, realistic ping floor, and ranked network experiments. |
| `07-video-research.md` | Digest of the 30-video / 19-channel `fortnite-tweaks` corpus. |
| `08-framesync-research.md` | Digest of the 26-video FrameSync Labs corpus. Benchmark-driven; **prefer it where the two corpora disagree.** |
| `09-latency-measurement.md` | How to actually measure input lag and frametimes on this machine. Read before any latency A/B. |
| `measure.ps1` | The capture harness. Run elevated, alt-tab into Fortnite, get FPS + click-to-photon latency. |
| `benchmarks.csv` | Structured FPS results. One row per measurement. |

## Current status

- Performance Mode (Alpha) is active. Biggest lever, already pulled. It forces off shadows, Lumen,
  Nanite, ray tracing and most post-processing — which is most of the "disable the animations" work.
- Power plan is already Ultimate Performance. Memory Integrity is already off. Secure Boot is on
  (and must stay on — Fortnite requires it on Windows 11).
- **Two confirmed config bugs found 2026-08-13** by reading `GameUserSettings.ini` directly:
  the game is running **windowed at ~923×915** instead of fullscreen 1920×1080 (T-007), and the
  frame cap is set to **180 on a 60 Hz panel** (T-006). Both are free to fix and both are now
  evidence-backed rather than generic advice. These are the highest-value open items.
- Network: measured, and now **closed**. About 30 ms to Epic NA-West over 5 GHz Wi-Fi with 0%
  packet loss on a clean 8-hop Comcast route. Region, Wi-Fi channel and adapter settings were all
  tested and ruled out. The one real defect — **upload-side bufferbloat in the cable modem** — was
  **fixed on 2026-08-13** with a 10 Mbps client-side QoS egress shaper, after confirming the
  rented Xfinity gateway cannot do SQM. Verified: ping under upload load fell from 71 ms avg /
  122 ms peak to **24 ms avg / 34 ms peak**. See `06-network.md` and log entry T-000g.
- Two YouTube corpora have been reviewed and digested (`07-`, `08-`). **Nothing from either was
  applied to the machine.** Net effect of the second one was to make the backlog *shorter*:
  T-011 (process priority), T-023 (BIOS power tweaks) and T-025 (disable VBS) are now **closed by
  measurement**, and T-022 was downgraded. Three small items were added: T-032, T-033, T-034.
- Baseline FPS: **still not measured — but no longer blocked.** PresentMon 2.3.1 was found already
  installed (bundled inside RTSS) and proven working here, so FPS *and* click-to-photon input lag
  are both measurable with no new software. Run `measure.ps1`. Nothing else should change until
  that baseline exists.

## The four facts that shape everything here

Full detail in `05-hardware.md`. Summary:

1. **60 Hz display.** Frames above ~60 are invisible. Target a flat, stable 60 with clean
   frametimes — not a higher average.
2. **4 GB VRAM is the scarce resource**, not system RAM. Background GPU apps cost real frames.
3. **32 GB RAM, dual channel, ~18 GB free, page file peak 468 MB.** Memory is a non-issue. The
   2933 MT/s speed is the CPU's official limit, not a misconfiguration.
4. **Thermals are the true limiter.** 73 °C GPU at near-idle, 50 W GPU cap, workstation chassis.
   Cooling beats settings for sustained framerate.

## Ground rules

1. One change per test. Two changes at once means you learn nothing.
2. No number goes in `benchmarks.csv` unless it was collected via `03-test-protocol.md`.
3. No memory-injecting "FPS booster" utilities. Config edits are fine; injection into the
   Fortnite process is an Easy Anti-Cheat / BattlEye ban risk and is not worth 5 frames.
4. `Engine.ini` `[SystemSettings]` cvar overrides are largely ignored or reset by current
   Fortnite builds. Do not spend time there without evidence it still works.
5. Never disable Secure Boot. It breaks Fortnite on Windows 11.
6. No generic TCP, MTU, Nagle, port-forwarding or "gaming DNS" tweak is accepted without an A/B
   latency test. Fortnite gameplay is mostly UDP, and DNS does not control established-match ping.
7. Ping results drift with time of day. The NA-West floor moved 22 ms → 30 ms inside 25 minutes on
   2026-08-13. Any latency A/B must be run as **A/B/A**, or the drift will be misread as a result.
