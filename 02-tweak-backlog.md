# 02 — Tweak backlog

Ranked for **this specific machine**: ThinkPad P15 Gen 1, i7-10750H, Quadro T1000 4GB (50W cap),
32GB dual channel, 1080p **60Hz**, already running Performance Mode (Alpha).

Read `05-hardware.md` for the hardware, then `04-tweak-log.md` entries **T-000h and T-000i** for the
two measured baselines that this ordering is now based on.

Confidence: `[high]` = well established · `[medium]` = usually true, verify · `[low]` = test it yourself

---

## STATUS AFTER TWO MEASURED BASELINES — 2026-08-13

Everything in this file used to be theory sourced from 56 YouTube videos. Two PresentMon captures
totalling **180 seconds and 21,124 frames** have now replaced most of it. Read this block before
touching anything below it.

**1 · The machine is hard CPU-bound.** `MsCPUBusy` **8.14 ms** vs `MsGPUBusy` **3.86 ms** against an
8.49 ms frametime. The GPU is idle for more than half of every frame and never exceeded **51%**
utilisation across 120 seconds. **Lowering graphics settings cannot raise this framerate.** T-003,
T-005, T-022 and T-028 are dead as FPS levers and have been demoted accordingly.

**2 · Framerate is no longer the problem.** Run 2 measured **117.8 avg / 71.8 1% low / 40.5 0.1%
low** on a **60 Hz** panel. The 1% low is *above refresh*. Only **54 frames out of 14,128 (0.38%)**
missed the 16.7 ms budget, only 3 exceeded 33 ms, and **zero** exceeded 50 ms. More than half of all
frames (7,504) came in under 8.3 ms. There is no framerate deficit left to chase on this display.

**3 · The "30-second cliff" from run 1 did not reproduce, and was not a hardware throttle.**
Run 2 held **101–131 fps flat across all twelve 10-second buckets**. The telemetry sidecar settles
it: `\Processor Information(_Total)\% Processor Performance` read **135–140% for the entire 120
seconds** with no downward trend, meaning ~3.5 GHz sustained all-core turbo that never decayed.
**The Intel PL2 → PL1 turbo-expiry hypothesis is dead.** Run 1's second half pinned at *exactly*
60.0 / 59.9 / 60.0 fps with `MsCPUBusy` 16.4 ms ≈ the 16.67 ms frame budget — that is the signature
of Fortnite's unfocused/background frame cap, i.e. the game lost foreground focus partway through
the capture. **Rule added to `03-test-protocol.md` thinking: never alt-tab during a capture.**

**4 · Thermals are real but are not currently costing frames.** GPU sat at a flat **68–69 °C,
21.2–21.6 W against a 50 W cap, 988–1307 MHz against a 1530 MHz max** for the whole run, reporting
`SW Power Cap: Active` and `SW Thermal Slowdown: Active`. So the card *is* being governed — but it
is also idle half the time, so the governor is not what is limiting output. Meanwhile the CPU
sustained full turbo in the same chassis. **T-020 is downgraded from `[high]` to `[medium]`.**

**5 · Click-to-photon latency is not obtainable with this instrument.** `MsClickToPhotonLatency` came
back **empty across both runs (180 s)**. `MsAllInputToPhotonLatency` collapsed from n=310 in run 1 to
**n=2** in run 2. The consistent explanation: run 1's 310 samples came from menu clicks during the
light opening segment, and in actual gameplay Fortnite takes aim/fire through **Raw Input**, which
PresentMon's ETW input tracking does not see here. `MsPCLatency` (Reflex) is also empty, so Reflex
markers are not reaching PresentMon either. **The latency metrics we can actually trust on this
machine are per-frame and complete (n=14,128):**

| metric | avg | p50 | p95 | p99 |
| --- | --- | --- | --- | --- |
| `MsRenderPresentLatency` | 2.74 | 2.38 | 5.07 | 13.64 |
| `MsUntilDisplayed` | 2.74 | 2.38 | 5.07 | 13.64 |
| `MsGPULatency` | 2.39 | 2.03 | 4.70 | 13.28 |
| `MsCPUBusy` | 8.14 | 7.84 | 11.20 | 13.59 |
| `MsCPUWait` | 0.35 | 0.33 | 0.45 | 0.52 |

Use **`MsUntilDisplayed` p99 and `MsCPUBusy` p99** as the A/B latency yardstick, not click-to-photon.

**Reframed goal.** FPS is solved. What is left is (a) shaving CPU time per frame, because CPU time
*is* the frametime here, and (b) the input-device half of the latency chain, which is measurable by
spec sheet rather than by capture. Everything below is re-ranked on that basis.

---

## Tier 1 — the only items with a measured mechanism behind them

### T-021 · Cut CPU contention from background apps `[high]` — NOW THE #1 ITEM
Promoted to the top on 2026-08-13. When a game is CPU-bound, every millisecond another process
steals off a 6-core CPU comes straight out of the frametime. Measured cumulative CPU-seconds at
baseline, with Fortnite running:

| process | CPU-sec | note |
| --- | --- | --- |
| `FortniteClient-Win64-Shipping` | 64,483 | the game, 5,651 MB WS, priority Normal |
| `dwm` | 3,469 | unavoidable |
| **`Discord`** | **3,063** | 879 MB. Close it or use the web client while playing. |
| **`antimicro`** | **2,744** | see T-035 — the single most suspicious entry |
| `audiodg` | 1,794 | see T-029 |
| `Notion` (×2) | 1,193 | Electron |
| `MsMpEng` | 706 | Defender — stays on, see "Not doing" |
| **`ProcessLasso`** | **213** | see T-036 |

Also previously measured holding VRAM on a 4 GB card: Epic Games Launcher, Epic overlay renderer,
EpicWebHelper, Edge WebView2, Windows Terminal, SearchHost, IGCC.
- Disable the Epic Games Launcher in-game overlay; close the launcher once the game is running.
- Close Discord, browsers and Electron apps before playing.

**Method, from `08-framesync-research.md` — measure instead of guessing.** Process *count* is
irrelevant (70 vs 1,000 processes measured identical on three machines), but running background
*apps* measured **3–9% FPS lost**, and removing them **6–36% gained**. Process Explorer →
right-click a column header → Select Columns → Process Performance → tick **CPU Cycles** and
**Context Switch Delta**. That is the ranking that matters, not the task-manager percentage.

### T-035 · `antimicro` — remove or A/B it `[high]` — NEW, top new suspect
**2,744 CPU-seconds** at baseline for a 63 MB controller-to-keyboard input mapper. It matters more
than the raw number suggests for two reasons: it sits **directly in the input path**, synthesising
input events for a game whose bottleneck is CPU time, and it is the most plausible reason
PresentMon's ETW input tracking is behaving strangely (see status note 5).
- If a controller is not actually being used: close it, A/B/A, and if clean, remove it from startup.
- If it is being used: still A/B it once to price it, then decide.
This is the highest-value untested item on the list and it costs nothing to try.

### T-036 · Audit Process Lasso `[high]` — NEW
Process Lasso is **installed and running** (213 CPU-sec at baseline). It rewrites process priority
and CPU affinity at runtime, which makes it a confound for **every CPU measurement in this project**
and a candidate for run 1's regime change. It must be characterised before any further CPU work.
- Open it and record exactly what rules are active on `FortniteClient-Win64-Shipping.exe`
  (ProBalance, priority class, affinity, I/O priority) into `01-current-settings.md`.
- Note the baseline already showed Fortnite at `PriorityClass = Normal`, so nothing is currently
  forcing High — consistent with T-011, which measured High as no better than Normal.
- If no rules are active, close it entirely; it is pure overhead and a source of confusion.
**Do not have it "disable core 0"** — see "Not doing"; that needs more than six physical cores.

### T-001 · Baseline `[high]` — DONE, and now the reference
Two captures recorded. Run 2 (`measurements/2026-08-13_122942__T-001__baseline2.csv`, 120 s,
14,128 frames) is the **authoritative baseline**; run 1 is contaminated by the focus-loss event and
should only ever be cited for the shader-warm-up spikes. Numbers live in `benchmarks.csv`.
Re-run `measure.ps1` before and after every change from here on. Ground rules that now have teeth:
- **≥90 seconds**, in an actual match, foreground, never alt-tab mid-capture.
- Judge on **1% low** and **`MsUntilDisplayed` p99**, not average FPS.
- **<4% is noise.** Both corpora and our own bucket variance agree on that floor.
- A/B/A always.

### T-002 · Record Replays → Off `[high]`
Still worth doing and still unverified. Continuously serialises match state on the CPU thread, and
CPU time is the currency here. Shows up as fewer stutters rather than higher average.
Caveat from Lecctron: replays mostly cost SSD writes rather than frames — if they are actually
watched, leaving them on is defensible.

### T-010 · Windows Game DVR / background recording → Off `[high]`
Settings > Gaming > Captures. Still unverified. Classic CPU-side stutter source, so it belongs in
Tier 1 now rather than buried in Tier 3 where it used to sit.

---

## Tier 2 — plausible, cheap, unproven

### T-037 · 3D Resolution 70% → 100% `[medium]` — NEW, probably free
`GameUserSettings.ini` shows `DesiredScreenWidth=1344` / `DesiredScreenHeight=756` against
`ResolutionSize` 1920×1080 — exactly **70%**. The game is rendering at 1344×756 and upscaling, which
is why enemies at range look soft. Because the GPU is idle 55% of every frame with 45–51% headroom,
putting this back to **100% should cost little or nothing in FPS** and is a straight visual win.
This also un-does a setting that is on this project's own rejected list as a permanent choice.
A/B it properly — if the 1% low drops more than 4%, revert.

### T-006 · Frame Rate Limit `[medium]` — RECOMMENDATION RETRACTED AND REWRITTEN
**This item previously said "cap to 60–70". That was wrong for this machine and is withdrawn.**
The capture shows `SyncInterval 0` and `AllowsTearing 1` on every one of 14,128 frames — the game is
running uncapped-to-refresh with tearing allowed. In that configuration, rendering *above* the
refresh rate genuinely lowers displayed latency, because each 16.7 ms scanout picks up a fresher
frame. Capping to 60–70 would **raise** input lag to buy consistency this machine already has
(1% low 71.8, zero frames over 50 ms). The heat argument also failed: the CPU sustained full turbo
for two minutes and the GPU never got near its power cap.
- **Leave the current 160 cap alone.** It is above refresh and above the measured 1% low.
- If this is ever revisited, test **120–144**, never 60–70.
- `FrontendFrameRateLimit=120` in the lobby is still pure waste heat; dropping it to 60 is free.

### T-020 · Thermal / power headroom `[medium]` — REWRITTEN 2026-08-13 after a GPU capability audit
**Correction to an earlier claim in this file and in `T-000i`: the GPU does NOT have a 50 W budget
with half of it spare. Its ENFORCED power limit is 23 W.**

| nvidia-smi field | value |
| --- | --- |
| `power.default_limit` | 50.00 W |
| `Requested Power Limit` | 50.00 W |
| **`enforced.power.limit`** | **23.00 W** |
| measured draw in-game | 21.2–21.6 W |

So the card ran at **~93% of the power it is actually allowed**, not 43% of 50 W. The driver asks
for 50 W and the platform refuses. This is Lenovo's embedded controller / Intelligent Thermal
Solution (`LITSSVC` is running) arbitrating a shared CPU+GPU chassis budget, and it is handing that
budget to the CPU — which, on a CPU-bound game, is arguably the correct call.

**The 23 W cap is not software-adjustable. Both levers were tested and both failed:**
- `nvidia-smi -pl 50` → *"Changing power management limit is not supported for GPU"*.
- Windows power-mode slider set to **Best Performance** (`ded574b5-...`), which on a P15 is supposed
  to invoke Lenovo Ultra Performance Mode → **enforced limit stayed at 23.00 W**, draw 21.4 W,
  no pstate change. Reverted; the slider was and is at its default position.

**The thermal story was also overstated.** Actual thresholds on this card: **slowdown 92 °C,
shutdown 97 °C, max operating 102 °C.** It runs at **68 °C** — 24 °C of headroom to the first
threshold. The `SW Thermal Slowdown: Active` flag is the *driver's software policy* enforcing the
platform power cap, **not** a hardware thermal event. `HW Thermal Slowdown` reads `Not Active` with
a lifetime counter of **0 us**. This card has never hit a real thermal wall.

**What this means practically.** The GPU cannot be made to draw more power from software. The only
remaining routes are physical (better cooling → more budget for the shared arbiter to hand out) and
firmware (`Config > Power > Intelligent Cooling Boost` in the UEFI menu, and installing Commercial
Vantage, which is **not** currently installed — only a bare `Lenovo` folder and the ITS driver).
And none of it would raise FPS today, because the bottleneck is the CPU.
Still worth the cheap end of the list, for sustained sessions and for the day this stops being
CPU-bound:
- Elevate the rear of the laptop for intake clearance. Free, and the largest single item here.
- Clean fans and exhaust vents.
- Cooling pad.
- Repaste if out of warranty — a 2020 machine is likely on dried paste.
- Lenovo Vantage → set the AC thermal profile to maximum performance.

### T-039 · Lock GPU clocks with `nvidia-smi -lgc` `[low]` — NEW, the one GPU lever that exists
**Verified supported on this card** (Quadro; most GeForce laptop parts refuse this):
`nvidia-smi -lgc 1300,1530` returned *"GPU clocks set to (gpuClkMin 1300, gpuClkMax 1530)"* and
`nvidia-smi -rgc` cleanly reset it. Requires elevation; does not persist across reboot.
It **cannot** create power headroom — the 23 W cap still binds, so the card will simply bounce off
it. The only reason to test it is *variance*: run 2 showed the SM clock wandering 988–1307 MHz with
one collapse to **360 MHz at t=11.5 s**, and a clock floor might make frame delivery more uniform.
Judge purely on `MsUntilDisplayed` p99 and the 0.1% low, not on average FPS.
**Risk:** forcing a clock floor under a hard power cap can increase temperature and steal budget
from the CPU, which is the actual bottleneck. A/B/A carefully and reset with `-rgc` afterwards.

### T-034 · Raise mouse DPI, lower in-game sens proportionally `[medium]` — PROMOTED
**Promoted from `[low]` 2026-08-13.** Now that the render pipeline is measured at 2.74 ms average
and the frametime is CPU-locked, the *device* half of the latency chain is the largest remaining
addressable chunk. FrameSync's 545K-view video measured **400 → 3200 DPI cutting input lag by about
5 ms** — that is nearly twice the entire average render-to-display latency of this machine.
Keep effective sensitivity identical: at 800 DPI / sens 1, use 1600 / 0.5 or 3200 / 0.25.
Tension: `07-video-research.md` recorded pros commonly running 800 DPI, and the feel change is
significant. Test in Creative before ranked. Free, and larger than any registry tweak on this list.

### T-032 · `Win32PrioritySeparation` 40 → 36 `[medium]` — PROMOTED, machine is NOT at default
`HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl` → `Win32PrioritySeparation`, decimal.
**Measured 2026-08-13 during a state audit: this machine reads `40`. The Windows default is `38`.**
Nothing in this project ever wrote that key. It is therefore a **pre-existing modification made
before this work started** — and 40 is precisely the value two videos in `07-video-research.md`
recommend, without benchmarks. Someone has run a tweak guide or a tweak utility on this machine.
**Standing implication for the whole project: do not assume any Windows setting is at its default.
Measure it.** Other keys should be spot-checked against stock values before they are A/B'd.
FrameSync Labs' only explicitly non-sponsored video tested every value from 20–26 and 36–42:
**36 gave the best average FPS and the best 0.2% / 1% lows**, 20 second, 41 third, and latency was
identical across the whole range. A second video measured up to 7.7% on 1% lows at 36. **40 was not
among the winners in either test**, which makes the current value worse than both the stock 38 and
the target 36 on the only benchmarks available.
Promoted from `[low]` because this is no longer "apply a speculative tweak" but "revert an
unexplained non-default value to a measured-better one". One DWORD, no restart, instantly
revertible, targets 1% lows — the metric that still has room on this machine.
A/B **40 → 36**, and record 38 as the third arm if the first two are close.
**Coordinate with T-036 — Process Lasso may be overriding scheduling behaviour anyway, and it is a
prime suspect for having set this value in the first place.**

### T-008 · Strip animated cosmetics `[medium]`
Plain skin, wrap, pickaxe. No particle back bling. Free, permanent, and CPU-side — which is now the
side that matters.

### T-029 · Audio → Sound Quality: Low `[medium]`
`audiodg` burned **1,794 CPU-seconds** at baseline, which puts real numbers behind this for the
first time. leStripeZ notes the in-game description itself flags it as performance-affecting.
**Trade-off:** Codelife reports pros deliberately use High for footstep clarity. Judge the FPS side
on 1% lows and the audio side by ear. Not a free win — a real trade.

### T-030 · Bind "Switch Quick Bar" to an unused key `[low]`
Codelife, citing the pro Veno: leaving this action *unbound* introduces a small input delay when
swapping to builds. Zero cost, zero risk, unverified claim.

### T-038 · Power-plan boost mode 4 → 2 `[low]` — NEW, weak
The AC power plan runs `Processor performance boost mode = 4` (Efficient Aggressive); mode 2 is
plain Aggressive. Logged for completeness, but the evidence against it is already in hand: the CPU
held 135–140% of base clock for 120 seconds without decaying, so there is no boost behaviour
visibly being left on the table. Low priority, and pair it with T-033 rather than testing alone.

### T-033 · Power plan A/B — Ultimate Performance vs Balanced `[low]` — DOWNGRADED
**Downgraded from `[medium]`.** Two separate FrameSync tests found no difference, and our own
telemetry now shows sustained turbo and a GPU nowhere near its power cap on the current plan — so
there is no observed problem for a plan change to fix. Run only as a curiosity, A/B/A, judged on
minutes 5–10 of a session.

---

## Tier 3 — blocked, or dead ends kept for the record

### T-004 · CPU-bound vs GPU-bound check — CLOSED `[high]`
**Closed 2026-08-13 by measurement.** Answer: **hard CPU-bound.** `MsCPUBusy` 8.14 ms vs `MsGPUBusy`
3.86 ms, GPU utilisation 30–51%. This inverts the original expectation, which assumed a T1000 at
1080p would be GPU-bound. It is the single most consequential finding in the project because it
invalidates the entire graphics-settings class of tweaks.

### T-007 · Fullscreen at native 1920×1080 — CLOSED `[high]`
**Closed 2026-08-13. Applied by the user and verified.** `GameUserSettings.ini` now reads
`PreferredFullscreenMode=1`, `LastConfirmedFullscreenMode=1`, `1920×1080` — previously mode 2 at
923×915. `PresentMode` came back **`Hardware: Independent Flip` at 100% of 14,128 frames**, which is
direct proof the desktop compositor is out of the frame path and the up-to-16.7 ms DWM tax is not
being paid. Because the change was made *before* the first baseline there is no before-number, so
the predicted size of the win is unverifiable and will not be re-tested.

### T-009 · NVIDIA Reflex → On `[medium]` — BLOCKED, cannot be measured
Still the right setting in principle, but `MsPCLatency` came back **empty across both captures**, so
Reflex latency markers are not reaching PresentMon and an A/B cannot currently be scored. RTSS's
Fortnite profile does have `ReflexLowLatency = 1`, `ReflexGetLatency = 1` and
`ReflexSetLatencyMarker = 1`, but RTSS statistics are off (`EnableStat = 0`) and RTSS injects, which
is a separate anti-cheat consideration from PresentMon. **Investigate why markers are missing before
spending a test slot on this.**
- If it is set On, leave it On. Do **not** use On+Boost: Lecctron warns Boost adds up to 5 °C and
  says explicitly not to use it on an old single-fan Quadro, which is exactly this card.
- `LowInputLatencyModeIsEnabled=True` is already set — do not stack redundant options unmeasured.

### T-022 · NVIDIA Control Panel profile — UN-ACTIONABLE, and moot `[low]`
**Two independent reasons this is dead.** First, it cannot be done: there is **no NVIDIA Control
Panel, NVIDIA app or GeForce Experience installed on this machine** — only the bare 596.86 driver,
with no `NVIDIA Corporation\Control Panel Client` folder present. Second, even if it were installed,
it is aimed at the GPU, and the GPU is idle half of every frame. `08-framesync-research.md` already
measured the popular NVCP profile at 3.4–4% average FPS at best, nothing on 1% lows, and input lag
**up** by as much as 1 ms. Nothing to do here.

### T-028 · NVIDIA shader cache size → 10 GB `[low]` — DEMOTED, also un-actionable
Demoted with T-022 and for the same reason — it lives in the NVIDIA Control Panel, which is not
installed. The underlying concern was real: run 1 showed 233.5 ms and 172.6 ms frametime spikes in
the first 14 seconds, which is textbook shader compilation. But run 2's **worst frame was 36.2 ms**
and nothing exceeded 50 ms, which means the cache warmed and stayed warm. **Not a live problem.**

### T-005 · Textures → Low, High Resolution Textures → Off `[low]` — DEMOTED, not an FPS lever
Demoted from `[high]` 2026-08-13: the machine is CPU-bound, so this cannot raise the framerate.
The *VRAM* argument survives on its own — 4 GB is genuinely tight and running out causes hitching
rather than a lower average. Worth one check, not a test slot:
Epic Games launcher → Fortnite → three dots → Options → confirm **"High Resolution Textures"** is
unchecked. Lecctron's framing is the right one: textures cost nothing *until you run out of VRAM*.

### T-003 · View Distance → Near — DROP `[low]`
Was already downgraded once by the video corpus; now dead twice over. Lecctron states view distance
only controls how far *item pickups* render, Codelife reports pros run it *higher* for early loot
and build spotting, and the CPU-bound finding removes the last reason to try it. Setting it to Near
costs visibility and buys nothing. **Do not test.**

### T-031 · Hardware-accelerated GPU scheduling — A/B `[low]`
Settings > System > Display > Graphics > Advanced. In theory attractive for a CPU-bound game because
it moves scheduling work off the CPU — which is now confirmed to be the bottleneck, so this is the
one GPU-adjacent item that keeps a live mechanism. Against it: FrameSync measured "up to 2.8% on 1%
lows" once and "nothing significant" another time, two sources report it *causing* stutter, and it
needs a restart per state. Bias toward **off**; A/B/A properly or skip.

### T-011 · Process priority → High — CLOSED, no measurable effect `[high]`
**Closed 2026-08-13.** Measured twice by FrameSync Labs: *"running the game in High versus normal
priority didn't make a big difference and it's within the margin of error."* Their 545K-view input
lag video opens by listing "set priority to high" as its example of recycled Windows XP advice.
Our own baseline confirms Fortnite is running at `PriorityClass = Normal` and performing fine.
One caveat kept: it can help *if other background apps run above normal priority* — that is a
background-app problem (T-021) and a Process Lasso question (T-036), not a priority problem.
**Never use Realtime** — it starves input, audio and system threads and causes hard stalls.

### T-012 · Launch arguments `[low]`
Modern Unreal ignores most of them; some cause instability. Skip unless bored.
The corpus offers `-lanplay` (NinjSZN, no evidence, self-admittedly outdated) and `-d3d11` to force
the legacy DX11 Performance Mode path. The latter is the only one worth consideration, and only as a
deliberate renderer A/B — which is now more interesting than it was, since a DX11 path could change
CPU cost per frame on a CPU-bound machine. Still `[low]`; discard the first 2–3 matches after it.

### T-013 · Lobby / menu frame cost `[low]`
Fold into T-006: `FrontendFrameRateLimit=120` on a 60 Hz panel is waste with no upside.

### T-023 · BIOS thermal and power profile — CLOSED, do not do `[high]`
**Closed 2026-08-13 by `08-framesync-research.md`.** FrameSync disabled every power-saving feature in
Windows and BIOS (C-states, ASPM, PSS, PSU idle control, dynamic tick, CPU idle, power throttling,
GPU P-states) on both an Intel and an AMD machine and measured **no FPS gain and no input-delay
gain**, at a cost of **+35% power on AMD and up to +70% on Intel**. Their own caveat names this
exact situation: *"I'd highly recommend keeping throttle states enabled, especially on laptops or
PCs with mediocre cooling."* **Reinforced by our own telemetry:** the CPU already sustains 137% of
base clock for two minutes unaided, so there is no suppressed boost behaviour to unlock.
Still worth doing while in this menu: confirm **Intel Turbo Boost is enabled**. Nothing else.

### T-024 · BIOS graphics device mode `[low]`
`Config > Display > Graphics Device`, if present. Discrete-only removes Optimus copy overhead, which
is a CPU-side cost and therefore newly relevant — but it also raises chassis heat. No Intel GPU
appeared in adapter enumeration, suggesting this may already be discrete-only. Verify before acting.

### T-025 · Disable VBS — CLOSED, near no-op here `[high]`
**Closed 2026-08-13.** Quantified elsewhere at 9.4% low-end / 2.2% mid / 1.5% high-end in Fortnite,
but this machine already reports `SecurityServicesRunning = {0}` and `HVCI Enabled = 0` — VBS is
configured but **not actually running**, so there is nothing to reclaim. It would also break
Hyper-V / WSL2 for no gain.

### T-026 · BIOS update `[low]`
Currently N30ET52W (1.35) from Aug 2023. Check Lenovo Vantage for newer. Expected gain: near zero.
Do it for stability and microcode, not for FPS.

---

## Network items

Live in `06-network.md`. **N-004 upload bufferbloat is CLOSED and FIXED** — a 10 Mbps default egress
QoS shaper (`FN-UploadShaper`, ~88% of the measured 11.4 Mbps line rate) took ping under upload load
from **30 / 71 / 122 ms down to 18 / 24 / 34 ms**, a 47 ms average and 88 ms peak improvement, at a
cost of roughly 12% slower bulk uploads. A pre-existing `Fortnite` QoS policy (DSCP 46, throttle -1)
exempts the game from the shaper and was deliberately left untouched.

Route, region and Wi-Fi link are all healthy and near their floor. Region (N-003), Wi-Fi channel
(N-005) and Throughput Booster (N-007) were tested and closed.

**N-001 `[high]` — NOW THE #1 NETWORK ITEM. Plug in an Ethernet cable.**
**Promoted 2026-08-13 with hard evidence. The previous note said "do not expect much" — that was
wrong and is retracted.** A hop-by-hop breakdown isolated where the latency actually lives:

| segment | RTT | verdict |
| --- | --- | --- |
| laptop → own gateway (hop 1, Wi-Fi) | **6 ms typical, 4–12 ms** | should be **<1 ms** on a cable |
| gateway → Comcast edge (hops 2–8) | ~15 ms total, flat | healthy, normal DOCSIS |
| total to Epic NA-West | 18–25 ms median | at its floor |

**About 5–6 ms of the total is being spent crossing the room.** Worse, a 25-packet idle run to the
*local gateway* produced a **177 ms spike**, and the matching run to Epic produced **241 ms, 88 ms
and 68 ms** spikes. A 177 ms spike to your own router on an idle network cannot be the ISP, cannot
be bufferbloat (that is fixed and this was idle) and cannot be routing — **it happens on the Wi-Fi
link**. That is almost certainly what is felt as "ping ranging around 30": the median is ~22, the
spikes are what break fights.
Link is otherwise healthy — `Wiifii`, 5 GHz ch 157, 802.11ac, 85% signal, Rx 780 / Tx 650 Mbps, and
a fresh scan confirms it is **the only network in range** (no `xfinitywifi` public hotspot sharing
airtime, so that lever does not apply here).
Expect from a cable: **−5 ms median and, more importantly, elimination of the spike class.**
The `Intel(R) Ethernet Connection (11) I219-V` is present and `Media disconnected`. Just needs
a cable. A/B/A with 50-packet runs to `3.101.95.110` plus a gateway run, and record max and jitter,
not just the average.

**N-009 `[medium]` — NEW. Ask Xfinity about Low Latency DOCSIS (L4S).** Comcast's LLD/L4S rollout
was live to **10 million+ homes as of January 2026**, at no extra cost, and it specifically targets
the queueing and DOCSIS-scheduling delay that sits between hop 1 and hop 2 here. Requirements: an
**XB7, XB8 or XB10 gateway** on a vCMTS-served segment. The current gateway model could not be read
over HTTP — **check the sticker on the back of the box.** If it is an XB6 or older, a free swap to
an XB7/XB8 is the single biggest remaining ISP-side lever. Published target is sub-5 ms at the
99th percentile for non-queue-building traffic like game packets.
Note: the pre-existing `Fortnite` QoS policy on this machine already marks the game's traffic
**DSCP 46**, and DOCSIS LLD classifiers can use DSCP to select the low-latency queue — so that
policy may become actively useful if LLD is enabled. Another reason not to delete it.

**N-008 `[medium]`.** Epic Games launcher → Settings: turn off **"Allow installs during gameplay"**,
plus run-at-startup, minimize-to-tray and notifications. A launcher update firing mid-match is
exactly the upload event the shaper now absorbs — but not generating it is still better.

**N-002 `[low]`.** Primary DNS `64.6.64.6` resolves in **1847 ms** (retired Neustar); `8.8.8.8`
resolves in 32 ms. Affects logins and menus only — gameplay is UDP on an established session.

---

## Not doing

The first group is longstanding. The second group was added 2026-08-13 after reviewing 30 Fortnite
optimization videos — full reasoning in `07-video-research.md`. The third was added after reviewing
26 FrameSync Labs videos — `08-framesync-research.md`.

- **Disabling Secure Boot** — Fortnite requires Secure Boot + TPM 2.0 on Windows 11. This locks you
  out of the game. It is currently ON and must stay ON.
- **"Allocating" or "dedicating" RAM to Fortnite** — no such mechanism exists for native Windows
  games. That is a Minecraft-Java heap concept. Fortnite allocates on demand.
- **RAM speed / XMP tuning** — no XMP in ThinkPad BIOS, and 2933 is the i7-10750H's official
  controller limit. Already at spec, already dual channel. *(The corpus recommends XMP/DOCP/EXPO in
  at least three separate videos. It does not apply to this machine.)*
- **Disabling or shrinking the page file** — peak usage 468 MB, costs nothing, disabling causes crashes.
- **A custom page file of ~1.5× RAM (49152 MB)** — recommended by two videos. Measured peak usage is
  468 MB. This would consume ~48 GB of SSD for zero gain.
- **iGPU shared memory / UMA frame buffer BIOS setting** — irrelevant, rendering happens on the
  discrete T1000 with its own VRAM.
- **Buying more RAM** — 32 GB with 18 GB free. Money would go to cooling or a faster machine.
- **`Engine.ini` cvar edits** — blocked / ignored / reset by patches.
- **Third-party tweak injectors** — anti-cheat ban risk.
- **3D Resolution below 100% as a permanent setting** — destroys enemy readability. *(Note: it is
  currently at 70%. See T-037 — raising it back is now an active item.)*
- **Changing the matchmaking region** — measured; NA-West is already selected and optimal by 37 ms.
- **Changing the Wi-Fi channel** — measured; no other 5 GHz networks exist in range.
- **TCP / Nagle / MTU registry "optimiser" packs** — Fortnite gameplay is UDP. These do nothing.

Added from the video review:

- **`TdrLevel = 0` / `TdrDelay` registry edits** — `TdrLevel=0` disables GPU timeout detection and
  recovery, converting a recoverable driver hang into a hard freeze or bugcheck. Worst possible
  machine for it: a thermally governed 50 W mobile GPU.
- **Downgrading the NVIDIA driver to 572.60 / 580.97 / 591.44 via NVCleanInstall** — those are
  GeForce consumer builds. This is a **Quadro T1000 on 596.86**, a professional-branch driver.
- **Above 4G Decoding + Resizable BAR** — the source's own condition is ">4 GB VRAM"; this card has
  exactly 4 GB, and the P15 Gen 1 BIOS is unlikely to expose ReBar at all.
- **Disabling SMT / hyperthreading** — the same source's rule is "6 cores or fewer → Auto". And on a
  CPU-bound machine, removing threads is the wrong direction entirely.
- **Disabling Windows Defender and blocking Windows Update** — presented as routine in one guide.
- **Reinstalling Windows 11 23H2 or Windows 10 22H2** — not a rational trade for a 60 Hz panel.
- **"Disable mitigations"** — security off for low single digits, plus anti-cheat risk.
- **MSI Mode Utility v3 / interrupt-mode registry toggling** — third-party tool writing interrupt
  configuration; wrong device selection can leave the machine unbootable. Gains unverified.
- **Paid tweak suites (Hone, EXM, Paragon, Risxn/Rizen, Ginxy)** — the corpus's own benchmark video
  scores two of them 4/10 and 5/10 with *worse* input delay.
- **"Ping boosters" (ExitLag, GearUP)** — three sponsored placements claiming 40→8 ms. Measured
  reality here: NA-West 17/22/34 ms, 0% loss, clean 8-hop route, region already optimal. There is no
  bad route to fix, and a proxy adds a hop.
- **Changing DNS to lower in-match ping** — overclaimed. Gameplay is UDP on an established session.
- **Chris Titus WinUtil** — not malicious and genuinely popular, but it applies dozens of changes at
  once, which breaks ground rule 1.

Added from the FrameSync Labs review. These are rejected because someone **measured** them:

- **Timer resolution** — tested across 10 games: ~0.7% latency change, ≤1% FPS, and **Fortnite
  specifically measured slightly *worse* input latency**.
- **Mouse data queue size** — end-to-end and mouse latency **completely unaffected**; only polling
  *consistency* changed. The tester bricked a mouse setting it too low, with no easy revert.
- **Choosing a "CPU-direct" USB port** — differences measured in **microseconds**, and: *"if you have
  an Intel processor, this wouldn't really matter."* This is an Intel machine.
- **Trimming Windows process count** — 70 vs 1,000 processes measured identical on three machines.
  It is the *apps*, not the count. See the method under T-021.
- **Disabling CPU idle / unparking all cores / idle thresholds to 100%** — *"you might be shooting
  yourself in the foot and tanking your performance."* A separate test found **letting Windows manage
  core parking was 2.5% avg / 3.5% lows better**. Our telemetry agrees: turbo is already sustained.
- **Disabling core 0 via Process Lasso** — measured up to 8% on 1% lows, but the source's own
  prerequisite is **"more than six and preferably eight physical cores."** This CPU has exactly six.
- **Disabling NIC offload, interrupt moderation and flow control** — the source's own caveat is
  *"only recommended for newer and more powerful processors."* A 2020 6-core mobile i7 is the case
  being warned about.
- **`FastSendDatagramThreshold` registry DWORD** — a real tunable offered with no measurement.
- **Chasing NVIDIA driver versions** — ~20 drivers tested across two videos; most land inside noise
  and latency differences are in microseconds. Leave 596.86 alone.
- **Custom OS builds / AME playbooks / FSOS** — four videos, all promoting the channel's own OS.
  Their own disclaimer: *"if you're heavily CPU or GPU bottlenecked, you might not see such huge
  performance gains."* We are now **measured** as heavily CPU-bound, so that disclaimer applies
  directly. Their debloat video also warns Fortnite tournament play **requires the security
  mitigations left enabled** or anti-cheat blocks you.
