# 04 — Tweak log

Append-only. Newest entries at the bottom. Never delete or rewrite a past entry — a tweak that
did nothing is a useful result and stops it being retried in three weeks.

## Entry template

```
### T-000 · <short name>
- Date:
- Change:
- Reason:
- Baseline (A avg / A 1% low / B avg / B 1% low):
- After    (A avg / A 1% low / B avg / B 1% low):
- Feel:
- Verdict: keep | revert | inconclusive
- Notes:
```

---

### T-000 · Folder created, starting state
- Date: 2026-08-13
- Change: none — documentation only.
- Reason: Establishing a place to track Fortnite tuning so results are not re-litigated from memory.
- Starting state: Rendering Mode is already **Performance Mode (Alpha)**. Some OS-level and driver
  tweaks reportedly already done, specifics unconfirmed. Goal stated by the user was reducing
  in-game animation and effect load for more FPS.
- Key finding while setting this up: Performance Mode already forces off shadows, Lumen, Nanite,
  ray tracing and most post-processing — which is exactly the "disable the animations" work most
  guides describe. So the headline lever is already pulled, and remaining gains are smaller and
  mostly CPU-side (replays, view distance, background load, cosmetics).
- Verdict: n/a
- Next: T-001 baseline measurement. No further changes until a baseline exists.

---

### T-000b · Hardware audit — major reframe
- Date: 2026-08-13
- Change: none — measurement only. Queried the machine directly rather than relying on assumptions.
- Reason: User asked three questions: BIOS tweaks for speed, dedicating more RAM to Fortnite, and
  setting the Fortnite process to High priority. All three needed the real spec to answer honestly.
- Findings: full table in `05-hardware.md`. ThinkPad P15 Gen 1, i7-10750H, Quadro T1000 4GB at a
  50W cap, 32GB dual-channel at 2933 MT/s, 1080p **60Hz**, Ultimate Performance plan already active,
  Memory Integrity already off, Secure Boot on, GPU sitting at **73 °C near idle**.

**Answers to the three questions:**

1. **Dedicating RAM to Fortnite — not possible, and not needed.** No such mechanism exists for
   native Windows games; that is a Minecraft-Java heap concept. Measured state: 32GB installed,
   ~18GB free, page file peak usage 468MB in the machine's entire history. Zero memory pressure.
   Already dual-channel, which is the part that would actually have mattered. The 2933 MT/s speed
   is the i7-10750H's official memory controller limit and the factory configuration for this
   model — not a misconfiguration, and ThinkPad BIOS has no XMP toggle regardless.

2. **High process priority — marginal.** Windows already prioritises the foreground application.
   Typical result is 0-2%, usually inside noise, and it resets on every launch. Never set Realtime;
   it starves input, audio and system threads. Logged as T-011 `[low]` — measurable, not promising.
   The same effort spent on T-021 (closing background GPU clients) is worth more on a 4GB card.

3. **BIOS — limited on a ThinkPad, but not empty.** No XMP, no CPU overclocking, no undervolting
   (Lenovo locked FIVR after the Plundervolt CVE). What does exist: thermal/power profile under
   `Config > Power` (T-023), possibly a hybrid-vs-discrete graphics toggle (T-024), and a BIOS
   update from 1.35 (T-026). **Secure Boot must not be disabled** — Fortnite requires it plus
   TPM 2.0 on Windows 11, so turning it off locks the user out of the game.

**The reframe that matters more than any of the three:** the display is **60 Hz**. Frames above ~60
are not visible. The correct goal is a flat, stable 60 with clean frametimes, not a higher average.
Combined with a 50W GPU cap and 73 °C idle temps, this means **cooling work beats settings work**
for anything measured past the first few minutes of a session.

- Verdict: n/a — informational
- Next: still T-001. Baseline first, then T-020 (thermals) and T-021 (background GPU clients).

---

### T-000c · Network latency audit
- Date: 2026-08-13
- Change: none — measurement only. Full results and experiment order are in `06-network.md`.
- Reason: User reports about 30 ms in Fortnite and wants to determine whether local configuration
  can reduce it.
- Connection: Intel AX201 over 5 GHz Wi-Fi, channel 157, 802.11ac, -52 dBm / 87% signal,
  866.7 Mbps receive and 650 Mbps transmit. Intel I219-V Ethernet is available but disconnected.
- Local gateway result: 5–13 ms, 7 ms average, 0% loss. This makes Ethernet the highest-value A/B
  because the Wi-Fi hop is already consuming a measurable part of the total latency budget.
- Internet results: Google 17–40 ms / 21 ms average and Cloudflare 23–30 ms / 27 ms average, both
  with 0% loss. Download saturation left Google at 21 ms average, so no download-side bufferbloat
  appeared in this test.
- Regional proxy result: US West / Northern California best 25.7 ms; Oregon best 47.9 ms; US East
  82.5+ ms. These are routing clues, not Fortnite server measurements, but they put a 30 ms
  Fortnite result close to the observed west-region floor.
- Adapter state: driver current; maximum wireless performance; highest transmit power; prefer
  5 GHz; lowest roaming aggressiveness; packet coalescing and U-APSD off. No obvious Windows
  adapter setting remains to fix.
- DNS finding: configured primary `64.6.64.6` answered one Epic query in 1847 ms versus 32 ms from
  secondary `8.8.8.8`. Repeat before changing. DNS affects setup/login, not established-match ping.
- Verdict: healthy path; 30 ms is good and likely near the route floor. A stable mid-20s may be
  possible over Ethernet. A stable 0–10 ms is not a realistic configuration target on this route.
- Next: N-001 wired Ethernet A/B, then repeated DNS tests and upload-side bufferbloat testing.

---

### T-000d · Full test round — regional, bufferbloat, adapter A/B/A, game config
- Date: 2026-08-13
- Change: one temporary adapter change, tested and reverted. Everything else measurement only.
  Full results in `06-network.md`.
- Reason: User asked for the whole proposed test list to be run on the machine with real data.

**1. Matchmaking region — CLOSED, already correct.** 50-packet tests to Epic's published regional
endpoints:

| Region | Endpoint | min / avg / max | Loss |
|---|---|---|---|
| **NA-West** | 3.101.95.110 | **17 / 22 / 34 ms** | 0% |
| NA-Central | 18.88.1.169 | 53 / 59 / 66 ms | 0% |
| NA-East | 44.192.142.31 | 78 / 83 / 103 ms | 0% |

NA-West wins by 37 ms over the next best, and `GameUserSettings.ini` carries `"regionId":"NAW"` on
every recent selection — the right region is **already selected**. The earlier advice to go and set
the region manually was wrong and is retracted. N-003 closed.

**2. Route to NA-West is clean.** Gateway 2 ms, then Comcast `96.216.x` → `96.110.x` all 13–24 ms,
edge at `96.110.33.86` ~20 ms on hop 8. Hops 9–15 time out because AWS/Epic suppress ICMP —
**this is not packet loss**; the 50-packet test to the destination itself was 0% loss. Do not
misread the trace.

**3. Upload bufferbloat — the one real defect found.**

| Condition | NA-West ping | vs idle |
|---|---|---|
| Idle | 17 / 22 / 34 ms | — |
| Download saturated | 17 / 21 / 26 ms | 0 ms, clean |
| **Upload saturated** | **30 / 71 / 122 ms** | **+49 ms avg, +88 ms peak** |

The diagnostic that localises it: during that same upload load the **gateway stayed at 3 / 5 / 10 ms**.
The laptop, the Wi-Fi link and the router LAN side are all innocent — the queue filling up is the
**cable modem's upstream buffer**. Download is clean, so this is upload-only: textbook cable-modem
bufferbloat, D/F grade. Practical effect is that any background upload (sync client, OBS, the
always-on `cloudflared` tunnel) spikes ping from ~30 to 70–120 ms — intermittent, which is exactly
how it would be experienced. Logged as N-004 `[high]`: fix with SQM/CAKE shaped to ~90–95% of
measured upload, or simply keep the uplink clear while playing.

**4. Throughput Booster A/B/A — no effect, reverted.** Intel's generic guidance says Disabled.
Tested with an A/B/A specifically to separate the setting from time-of-day drift:

| State | NA-West avg | Gateway avg |
|---|---|---|
| Enabled (baseline, 50 pkt) | 22 ms | 7 ms |
| Disabled (20 pkt) | 28 ms excl. one 274 ms outlier | 7 ms |
| Enabled again (25 pkt) | 30 ms | 7 ms |

Gateway was **7 ms in all three runs**, and the final Enabled run was *slower* than the Disabled
run — so the variance is internet-side drift, not the adapter. No measurable effect.
**Reverted to `Enabled`, its original value; system left as found.** N-007 closed.
Side observation worth keeping: the NA-West floor drifted 22 ms at 04:15 → 30 ms at 04:38. The
player's reported ~30 ms is the honest current baseline; the 22 ms reading was a favourable window.

**5. 5 GHz neighbour survey — CLOSED.** `netsh wlan show networks mode=bssid` returned only
`Wiifii`. No competing 5 GHz networks exist in range, so channel congestion is ruled out and
channel 157 should be left alone. N-005 dropped.

**6. Delivery Optimization — downgraded to non-issue.** No policy key, no active transfers.

**7. `GameUserSettings.ini` — two real problems, both FPS-side rather than network-side.**
- `ResolutionSizeX=923` / `ResolutionSizeY=915` with `FullscreenMode=2` (windowed). **The game is
  running in a roughly 923×915 window, not 1920×1080 fullscreen.** That costs both frames and input
  latency through the desktop compositor. This turns T-007 from generic advice into a confirmed bug.
- `FrameRateLimit=180.000000` with `FrontendFrameRateLimit=120`, on a **60 Hz panel**. Confirms
  T-006 with hard evidence: up to 120 frames a second are being rendered and thrown away, heating a
  50 W-capped GPU that then throttles later in the session.
- Already correct and should be left alone: `bUseVSync=False`, `LowInputLatencyModeIsEnabled=True`,
  `bUseDynamicResolution=False`.

- Verdict: the network is healthy and near its floor. The only network work worth doing is
  controlling upload bufferbloat; every other network avenue is now closed by measurement.
  The larger remaining wins are the two game-config bugs above.
- Next: **T-001 baseline is still not done and now blocks everything.** Then T-007 (fullscreen at
  1920×1080) and T-006 (cap to 60–70), both free and both now evidence-backed.

---

### T-000e · Video corpus review — 30 Fortnite optimization videos
- Date: 2026-08-13
- Change: none to the machine — documentation only. **No tweak from the corpus was applied.**
  Full digest in `07-video-research.md`.
- Reason: User supplied a scrape at `C:\Users\LENOVO\yt_scrapes\fortnite-tweaks\2026-08-13`
  (30 videos, 19 channels, 315,502 transcript chars) and asked what is worth testing and using.
- Method: every claim was checked against the measured state in `05-hardware.md` and
  `06-network.md` rather than accepted on the video's authority. Transcripts were treated as
  claims to evaluate, not as instructions to execute.

**Corpus quality.** At least 9 of the 30 videos carry a paid placement for a tweaking tool or a
"ping booster", usually with a discount code. The folder also contains its own rebuttal, which is
what makes it worth keeping:
- FtSdommm benchmarked the paid suites: **EXM 4/10** ("basically worse than where I was already
  at"), **Paragon 5/10** (FPS locked to 30 on load, input delay worse), Hone 8/10.
- Lecctron applied several popular guides end to end and measured **~zero net FPS change**, calling
  Process Lasso "pretty much useless" and one widely-repeated tweak "fully placebo".
- The egø "review" of RisxnTweaks is an on-camera **paid partnership** with a discount code.
  Discarded as evidence.
- Worth noting: Lecctron's debunk video mocks the genre, while Lecctron's own 565K-view guide in
  the same folder pushes registry edits with a "23.7% better 1% lows" claim and no methodology.

**Adopted — 3 new items and 1 new network item:** T-028 (NVIDIA shader cache → 10 GB, targets
stutter and 1% lows), T-029 (audio Sound Quality → Low, a real trade against footstep clarity),
T-030 (bind Switch Quick Bar), N-008 (Epic launcher: disable installs during gameplay — the
cheapest mitigation for the measured N-004 bufferbloat), plus T-031 (HAGS A/B, `[low]`).

**Revisions to existing items, all driven by hardware specifics:**
- **T-009 changed from "On + Boost" to "On".** Lecctron warns Boost adds up to 5 °C and says
  explicitly not to use it on "an old Quadro graphics card that has a single tiny fan". That is
  literally this machine — Quadro T1000, 50 W cap, 73 °C at near-idle. Boost is now ruled out.
- **T-003 View Distance → Near downgraded `[high]` → `[low]`.** Two sources say view distance now
  only affects item-pickup rendering with no FPS cost, and that pros run it *higher* to spot loot.
  The item likely costs visibility for nothing.
- **T-005 gained an exact location:** Epic launcher → Fortnite → Options → uncheck **"High
  Resolution Textures"**. Best single find in the corpus given the 4 GB VRAM budget. Not yet
  verified whether it is currently checked.
- T-002 softened (replays cost SSD writes more than frames), T-006 corroborated, T-022 expanded
  with a thermal caveat on "Prefer maximum performance".

**Rejected — notable, with the measurement that kills each.** Full list in `07-video-research.md`.
- **Ping boosters (ExitLag, GearUP — 3 sponsored placements)** claiming 40→8 ms and "down to 1
  ping". Measured: 17/22/34 ms to NA-West, 0% loss, clean 8-hop route, region already optimal.
  No bad route exists to fix, and a proxy adds a hop. Physically implausible claims.
- **`TdrLevel = 0`** disables GPU timeout recovery — turns a recoverable hang into a hard freeze,
  on the worst possible machine for it.
- **NVIDIA driver downgrade to 572.60 / 580.97 / 591.44** — GeForce consumer builds. This is a
  Quadro T1000 on 596.86, a professional-branch driver. Wrong branch.
- **XMP/DOCP** (3 videos) — laptop SODIMM already at the CPU's official 2933 limit.
- **Custom 49152 MB page file** (2 videos) — measured peak usage is 468 MB.
- **Above 4G Decoding + ReBar** — the source's own condition is ">4 GB VRAM"; this card has exactly 4.
- Disabling Defender, blocking Windows Update, downgrading to 23H2, "disable mitigations",
  MSI Mode Utility, and all five paid tweak suites.

- Verdict: the corpus produced **3 genuinely useful new items and 4 useful corrections**, and a
  much longer list of advice that is wrong for this hardware. Net value is real but modest — the
  two confirmed config bugs (T-007, T-006) still outrank everything the videos offered.
- Notable gap: **nothing in 30 videos addresses either of this machine's actual limits** — a 60 Hz
  panel and sustained thermals on a 50 W-capped mobile Quadro. The corpus optimises for 240–480 Hz
  desktops. Weight all of it accordingly.
- Next: unchanged. **T-001 baseline still blocks everything**, then T-007 and T-006.

---

### T-000f · Second corpus review — FrameSync Labs, 26 videos
- Date: 2026-08-13
- Change: none to the machine — documentation only. **Nothing from this corpus was applied.**
  Full digest in `08-framesync-research.md`.
- Reason: User supplied a second scrape at
  `C:\Users\LENOVO\yt_scrapes\framesynclabs\2026-08-13` — 26 videos, one channel, 159,546
  transcript chars — and asked whether it had useful insight. It did.

**Why this corpus outranks the first.** It is a single benchmark-driven channel measuring with an
LDAT / Reflex latency analyzer, CapFrameX, LatencyMon and a wall power meter, running 20
consecutive passes to establish a standard deviation, then applying an explicit rule: **any change
under 4% is treated as noise**. That margin-of-error discipline is absent from all 30 videos in the
first corpus. Where the two disagree, prefer this one.

Conflicts of interest, recorded: Surfshark sponsors at least 4 of the 26; they sell optimization
sessions; and they publish their own custom OS and playbook, so the 4-video custom-OS cluster is
ranking their own product. The mitigating evidence is that their measurements repeatedly kill
tweaks they could have sold.

**Main value is subtractive — three of our own items are now closed:**
- **T-023 (BIOS thermal/power) → CLOSED, do not do.** Disabling every power-saving feature in
  Windows and BIOS produced **no FPS and no input-delay gain** on either Intel or AMD, for
  **+35% to +70% power draw**. Their own caveat names laptops with mediocre cooling. On a 50 W
  Quadro at 73 °C idle this is strictly negative.
- **T-011 (process priority) → CLOSED.** Measured twice, inside margin of error. This also
  retroactively answers the question asked directly in chat earlier today.
- **T-025 (disable VBS) → CLOSED.** Quantified at 9.4% / 2.2% / 1.5% by machine tier — but this
  machine reports `SecurityServicesRunning = {0}`, so VBS is not actually running and there is
  nothing to reclaim.
- **T-022 (NVCP profile) → downgraded `[medium]` → `[low]`.** A popular NVCP guide measured
  3.4–4% average at best, nothing on 1% lows, and **input lag up by as much as 1 ms**.

**Adopted — three new items:** T-032 (Win32PrioritySeparation → 36; one DWORD, no restart, targets
1% lows), T-033 (power plan A/B, since two tests found Balanced vs High Performance made no
difference while Ultimate Performance costs thermal budget here), T-034 (raise DPI and lower sens
proportionally — 400 → 3200 DPI measured ~5 ms off input lag).
T-021 also gained a real method: Process Explorer with **CPU Cycles** and **Context Switch Delta**
columns. Process *count* is irrelevant (70 vs 1,000 measured identical); background *apps* cost
3–9%, and removing them gained 6–36%.

**Independent confirmation of two things already measured here:**
- Their most-viewed video (573K) ranks **bufferbloat** third among real ping factors, names the
  same Waveform test we used, and names SQM as the fix. That is N-004, reached independently.
- *"TCP Optimizer... games — especially shooter games — use UDP... TCP is only used for HTTP
  connections, patches and possibly voice chat."* Exactly why the Nagle / `TcpAckFrequency` / MTU
  family was rejected here.

**Rejected, each because someone measured it:** timer resolution (Fortnite got slightly *worse*),
mouse data queue size (no latency change at all), USB port choice (microseconds, and irrelevant on
Intel), process-count trimming, unparking cores, disabling CPU idle, NIC offload / interrupt
moderation, `FastSendDatagramThreshold`, chasing driver versions, and the whole custom-OS cluster.
Two rejections turn on this machine's own numbers: **core-0 disabling needs ">six and preferably
eight physical cores"** and this CPU has exactly six; and NIC offload disabling is explicitly
"not for older processors".

**Contradictions recorded rather than resolved:** the channel argues both sides of NVIDIA Reflex
(one video measures off as 2.2% faster, a later one recommends Reflex + Boost) and both sides of
full-screen optimizations. T-009 stays an A/B; the Quadro thermal argument against **Boost** from
`07-video-research.md` still stands on its own. One useful method detail salvaged: full-screen
optimizations must be toggled on the **game executable**, not a desktop shortcut.

- Verdict: the best-quality source reviewed so far, and it made the backlog **shorter** — three
  items closed, one downgraded, three small ones added.
- Reinforced again: **60 → 240 Hz is worth about 12.5 ms of latency**, more than every software
  tweak in both corpora combined. The 60 Hz panel remains this setup's defining constraint.
- Next: unchanged. **T-001 baseline still blocks everything**, then T-007 and T-006.

---

### T-000g · Upload bufferbloat FIXED (N-004) + input lag is now measurable
- Date: 2026-08-13
- change_id: `N-004-shaper`
- Change: created a Windows Policy-based QoS **default egress shaper** capping this machine's
  total upload to 10 Mbps. **This is the first change in this log that actually modified the
  machine and stuck.**
- Reason: N-004 was the only real defect the entire network audit found. Ping to Epic NA-West
  went from ~22 ms idle to **71 ms average / 122 ms peak** the moment anything saturated upload.

**Why the corpus fix was not available.** Both corpora prescribe SQM / CAKE / fq_codel on the
router. Identified the gateway at `10.0.0.1` — MAC `70-54-25-bb-2f-7d`, HTTP 200,
`Server: Xfinity Broadband Router Server`, `TITLE=XFINITY`. It is a **rented Comcast/Xfinity
gateway with no SQM capability**, and the buffer that fills sits in the cable modem's upstream
queue, which is upstream of this PC. Router-side SQM is ruled out short of bridge mode plus a
third-party router. Any earlier implication that SQM was a simple next step was wrong.

**What was done instead — client-side shaping.** If the PC never hands the modem more than the
modem can drain, the modem's queue never fills. Measured true upload capacity first, 3 runs of
20 MB each: **11.34 / 11.38 / 11.48 Mbps** — unusually consistent. Shaped to **10 Mbps, about 88%
of line rate**, which matches the 90–95% SQM convention with extra headroom for DOCSIS overhead.

| change_id `N-004-shaper` | NA-West `3.101.95.110` under 3× parallel upload | gateway `10.0.0.1` |
| --- | --- | --- |
| **before** (no shaper) | min 30 / **avg 71** / max 122 ms, 0% loss | 3 / 5 / 10 ms |
| **after** (10 Mbps shaper) | min 18 / **avg 24** / max 34 ms, 0% loss | 4 / 6 / 9 ms |
| delta | **−47 ms average, −88 ms peak** | unchanged |

Identical load in both runs: a 40 MB file POSTed 3× concurrently to `speed.cloudflare.com/__up`.
The after-figures sit *at* the previously measured idle floor (17–30 ms, which drifted across the
session), so induced latency is now effectively **zero**. Gateway RTT was never the problem and
did not move, which confirms the queue was in the modem's WAN uplink, not the LAN.

**A pre-existing Fortnite QoS policy was already on this machine**, found at
`HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite`: app `FortniteClient-Win64-Shipping.exe`,
`DSCP Value = 46`, `Throttle Rate = -1`. Origin unknown — not created during this project. It was
**left untouched**, and it is load-bearing: a more specific app policy takes precedence over the
new default policy, so Fortnite is exempt from the shaper and gets its own queue rather than
sharing a bucket with bulk uploads. DSCP 46 marking itself is almost certainly ignored by Comcast
on the WAN, but it is harmless.

**Units gotcha, recorded so nobody gets this wrong later.** `New-NetQosPolicy` takes
`-ThrottleRateActionBitsPerSecond` in **bits**, but the registry stores `ThrottleRate` in
**bytes**. Passing 10000000 wrote `1250000`. Always read the key back after writing.

```powershell
# applied (elevated):
New-NetQosPolicy -Name 'FN-UploadShaper' -Default `
  -ThrottleRateActionBitsPerSecond 10000000 -PolicyStore 'localhost'

# revert cleanly:
Remove-NetQosPolicy -Name 'FN-UploadShaper' -PolicyStore 'localhost' -Confirm:$false
```

Took effect immediately — no reboot, no `gpupdate`. Prerequisites verified present: QoS Packet
Scheduler (`ms_pacer`) bound and enabled on Wi-Fi, QWAVE service running.

- Cost: bulk uploads are capped at 10 Mbps instead of 11.4, roughly 12% slower. That is the
  standard SQM trade and it is worth it.
- Honest scope: **this fixes a latent vulnerability, not an active everyday defect.** OneDrive is
  installed but was not running, and the +49 ms was produced by a deliberate 3× parallel upload.
  It will pay off during Epic patch uploads, cloud saves, Discord screenshare, OBS streaming and
  browser uploads — not while idle. Idle ping is unchanged at ~30 ms and nothing here moves it.
- **N-004 → CLOSED, fixed and verified.**

**Part 2 — input lag became measurable, with zero installs.**

A correction to what was said in chat earlier today: the claim that input lag could not be
measured on this machine without an LDAT or a Reflex-capable monitor was **wrong**. RTSS 7.3.7 is
installed and ships Intel **PresentMon 2.3.1** inside it, at
`C:\Program Files (x86)\RivaTuner Statistics Server\Plugins\Client\PresentMonDataProvider\PresentMon-2.3.1-x64.exe`.
A live 10-second capture confirmed it works here: 841 frames, and the CSV carries
`MsClickToPhotonLatency`, `MsAllInputToPhotonLatency`, `MsPCLatency`, `MsRenderPresentLatency`,
`MsGPUBusy`, `MsCPUBusy` and `PresentMode`. PresentMon is ETW-based and runs out of process — no
injection — which is why it is the right instrument to use alongside Easy Anti-Cheat.

Added `measure.ps1` to this folder and `09-latency-measurement.md` documenting the protocol.
`PresentMode` in the output doubles as direct evidence for **T-007**: `Composed: Flip` proves the
desktop compositor is in the frame path, `Hardware: Independent Flip` proves it is not.

- Verdict: one real defect fixed and verified by measurement, and the instrument that was blocking
  every latency item now exists and is proven working on this hardware.
- Next: **T-001 baseline is finally unblocked** — run `measure.ps1` with Fortnite in the
  foreground. Then T-007 and T-006, which can now be A/B'd with real latency numbers instead of
  theory.

---

### T-000h · T-001 BASELINE MEASURED — and the machine falls off a cliff at 30 seconds
- Date: 2026-08-13, 12:12–12:13
- change_id: `T-001`
- Raw: `measurements/2026-08-13_121205__T-001__baseline.csv` (1,879,325 B)
- Capture: 60 s, **6,996 frames, 100% `FortniteClient-Win64-Shipping.exe`** — no contamination
  from other processes, unlike the earlier diagnostic capture.

**Headline numbers**

| metric | value |
| --- | --- |
| average FPS | **116.7** |
| 1% low | **49.6** |
| 0.1% low | 25.3 |
| peak | 397.6 |
| input→photon p50 | **9.8 ms** (p95 24.2, p99 25.6, n=310) |
| click→photon | **not reported — no clicks fired during capture** |
| Reflex PC latency | not reported |
| PresentMode | **`Hardware: Independent Flip` 99.9%** |
| SyncInterval / AllowsTearing | 0 / 1 |

**T-007 → CLOSED (applied by the user before this capture, and verified).** `GameUserSettings.ini`
now reads `PreferredFullscreenMode=1`, `LastConfirmedFullscreenMode=1`, `ResolutionSizeX=1920`,
`ResolutionSizeY=1080` — previously mode 2 at 923×915. `PresentMode` proves the change took:
**the desktop compositor is out of the frame path**, so the up-to-16.7 ms DWM tax predicted for
T-007 is **not being paid**. The prediction that this would be the single biggest win was
therefore right in principle but is now spent — and because the change was made *before* the
baseline, there is no before-number. Not worth re-testing; the evidence it is working is direct.

**Also changed by the user, unlogged:** `FrameRateLimit` 180 → **160**, `LatencyTweak2` 2 → **1**.

**New finding — 3D Resolution is at 70%.** `DesiredScreenWidth=1344`, `DesiredScreenHeight=756`
against a `ResolutionSize` of 1920×1080. 1344/1920 = exactly 0.70. The game is rendering at
1344×756 and upscaling. This is on the project's rejected list as a permanent setting and it
explains why the GPU is barely working. **Raising it to 100% is now a free test** (see below).

**T-004 → CLOSED. Hard CPU-bound.**

| | avg | p95 | p99 |
| --- | --- | --- | --- |
| `MsCPUBusy` | **8.25 ms** | 17.26 | 19.88 |
| `MsGPUBusy` | **4.67 ms** | 7.61 | 8.23 |
| frametime | 8.57 ms | | |

CPU busy ≈ frametime; GPU busy is barely half of it. The Quadro T1000 is idle roughly 45% of every
frame, and 82% of every frame in the second half of the capture. **Consequence: lowering graphics
settings cannot raise this framerate.** Textures (T-005), view distance (T-003), effects and the
whole NVCP cluster (T-022) are dead ends for FPS on this machine and should be treated as such.

**THE MAIN FINDING — a hard performance cliff at t=30 s.**

| bucket | avg FPS | 1% low | `MsCPUBusy` | `MsGPUBusy` |
| --- | --- | --- | --- | --- |
| 0–10 s | 189.8 | 105.2 | 4.94 | 5.05 |
| 10–20 s | 175.7 | 89.4 | 5.35 | 4.54 |
| 20–30 s | 151.9 | 94.1 | 6.27 | 6.19 |
| **30–40 s** | **62.6** | 46.4 | **15.69** | **3.35** |
| 40–50 s | 59.9 | 46.2 | 16.40 | 3.04 |
| 50–60 s | 60.0 | 48.1 | 16.38 | 2.97 |

Framerate does not decay — it **halves and then pins at 60**. CPU time per frame **triples**
(5.3 → 16.4 ms) while GPU time per frame **falls** (4.5 → 3.0 ms). A GPU doing *less* work while
the frame takes *longer* means the CPU is starving it. `MsCPUWait` stayed at 0.32 ms average, so
this is not a frame limiter making the CPU idle — it is genuine CPU work time expanding.

Two hypotheses fit the shape, and this capture cannot separate them:
1. **Intel PL2 → PL1 turbo expiry.** Default Tau on H-series laptops is commonly 28 s. A cliff at
   ~30 s is the textbook signature. Supporting evidence: the GPU reports **`SW Power Cap: Active`
   and `SW Thermal Slowdown: Active` right now**, at 69–70 °C drawing only 21 W, clocking
   1095–1140 MHz against a 1530 MHz maximum — about 72% of rated clock. CPU and GPU share one
   thermal budget in a ThinkPad P15, and both degrading together points at that budget.
2. A scene transition (lobby → match). Weakened by `FrontendFrameRateLimit=120`: the first bucket
   ran at 189.8 fps, above the lobby cap, so the fast segment was probably not the lobby.

**WMI cannot settle this** — `Win32_Processor` reports `CurrentClockSpeed 2592 = MaxClockSpeed
2592` on this machine, i.e. base clock only, never real-time turbo. The correct instrument is the
performance counter `\Processor Information(_Total)\% Processor Performance`, where >100 means
turbo and <100 means throttled.

**Every large frametime spike is a CPU stall.** Worst 12, without exception, have `MsCPUBusy` ≈ the
whole spike and `MsGPUBusy` at 3–9.5 ms:

| t | frametime | cpuBusy | gpuBusy |
| --- | --- | --- | --- |
| 13.6 s | **233.5 ms** | 233.0 | 3.0 |
| 4.2 s | **172.6 ms** | 172.1 | 9.5 |
| 30.5 s | 72.4 ms | 72.2 | 7.0 |
| 5.4 s | 68.2 ms | 67.9 | 6.8 |

Only 11 frames of 6,996 exceeded 33 ms and only 4 exceeded 50 ms, so these are rare (0.16%) but
brutal — a 233 ms freeze is a quarter-second. Three of the four worst landed in the first 14
seconds, consistent with shader compilation or asset streaming warm-up rather than a steady defect.

**New suspects found while diagnosing, none yet tested:**
- **`antimicro` (PID 14940) has burned 2,744 CPU-seconds** — more than Discord. It is a controller
  input mapper that polls devices and injects synthetic input, which places it directly in the
  input path of a CPU-bound game. Highest-priority new item.
- **`ProcessLasso` (PID 8804) is running.** It can rewrite priority and affinity at runtime, which
  makes it a confound for every CPU measurement in this project and a candidate cause of the cliff.
  Its configuration was never audited.
- `Discord` 3,063 CPU-seconds / 879 MB.
- Fortnite itself: `PriorityClass = Normal`, working set 5,651 MB.
- Power plan: max processor state 100%, min 5%, **boost mode 4 (Efficient Aggressive) on AC**.
  Mode 2 (Aggressive) is a legitimate reversible A/B given a boost-related cliff.

**Harness upgraded to v2** (`measure.ps1`, 14,299 B) specifically to settle the cliff. It now runs
a background sampler alongside PresentMon capturing `% Processor Performance` plus GPU
temp/power/clock once per second, prints a 10-second bucket table with those columns aligned to
FPS and CPU/GPU busy, lists the worst 10 spikes, warns explicitly when a cliff is detected, and
nags if no click samples were recorded. Default duration raised 60 → **90 s** because 60 s only
just caught the cliff. Telemetry is written to a `__telemetry.csv` sidecar.

- Verdict: the baseline exists at last, and it immediately closed two backlog items (T-004, T-007)
  and invalidated a whole class of others. The real problem on this machine is **not graphics
  settings and not the network** — it is that the CPU loses roughly two thirds of its throughput
  30 seconds into a session.
- Next: re-run `measure.ps1 -Seconds 120 -ChangeId T-001 -Label baseline2` **while shooting**, to
  (a) confirm or kill the throttle hypothesis via `cpuPerf%`, and (b) finally get click→photon.
  Then **T-020 thermals** is the top item, not T-006.
- Backlog file not yet re-ordered for these findings. **(Done in T-000i below.)**

---

### T-000i · BASELINE 2 — the cliff did not reproduce and the throttle hypothesis is dead
- Date: 2026-08-13, 12:29–12:31
- change_id: `T-001`, label `baseline2`
- Raw: `measurements/2026-08-13_122942__T-001__baseline2.csv` (3,793,688 B)
- Telemetry: `measurements/2026-08-13_122942__T-001__baseline2__telemetry.csv` (2,624 B, 89 samples)
- Capture: **120 s, 14,128 frames, 100% `FortniteClient-Win64-Shipping.exe`**, in-match, foreground.

**This entry retracts the headline of `T-000h`.** The v2 harness was built specifically to decide
between two explanations for the 30-second collapse seen in run 1. It decided against both of the
ones on offer, and against the more alarming one decisively.

**No cliff. Twelve flat buckets.**

| bucket | frames | avg FPS | 1% low | `MsCPUBusy` | `MsGPUBusy` | **cpuPerf%** | GPU |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0–10 s | 1146 | 114.6 | 60.2 | 8.36 | 3.76 | **137.3** | 68.9 °C / 21.3 W / 1140 MHz / 36% |
| 10–20 s | 1010 | 101.0 | 58.7 | 9.55 | 5.64 | **137.9** | 69.0 °C / 21.6 W / 988 MHz / 46% |
| 20–30 s | 1098 | 109.9 | 69.4 | 8.74 | 3.79 | **137.5** | 69.0 °C / 21.3 W / 1239 MHz / 33% |
| 30–40 s | 1146 | 114.6 | 71.0 | 8.38 | 3.94 | **137.0** | 69.0 °C / 21.5 W / 1153 MHz / 34% |
| 40–50 s | 1179 | 117.8 | 76.6 | 8.14 | 3.23 | **136.2** | 69.0 °C / 21.6 W / 1307 MHz / 30% |
| 50–60 s | 1228 | 122.9 | 81.1 | 7.79 | 3.40 | **136.7** | 69.0 °C / 21.4 W / 1221 MHz / 37% |
| 60–70 s | 1300 | 130.0 | 80.1 | 7.36 | 3.38 | **137.2** | 68.9 °C / 21.3 W / 1192 MHz / 37% |
| 70–80 s | 1309 | 130.9 | 86.3 | 7.30 | 3.62 | **137.4** | 68.3 °C / 21.2 W / 1251 MHz / 41% |
| 80–90 s | 1183 | 118.3 | 77.4 | 8.11 | 3.40 | **136.6** | 68.4 °C / 21.2 W / 1252 MHz / 37% |
| 90–100 s | 1187 | 118.7 | 69.5 | 8.08 | 3.95 | **134.8** | 68.4 °C / 21.2 W / 1172 MHz / 40% |
| 100–110 s | 1158 | 115.9 | 76.6 | 8.29 | 3.70 | **135.9** | 68.4 °C / 21.4 W / 1183 MHz / 37% |
| 110–120 s | 1184 | 118.6 | 69.1 | 8.08 | 4.89 | **135.4** | 68.0 °C / 21.4 W / 1001 MHz / 51% |

**The `cpuPerf%` column is the answer.** `\Processor Information(_Total)\% Processor Performance`
read **134–140% for the entire 120 seconds**, with the slowest bucket being the *ninth*, not the
fourth, and a total drift of about 2 points end to end. Above 100 means turbo; the CPU held roughly
**3.5 GHz sustained all-core for two straight minutes and never decayed**.
**Intel PL2 → PL1 turbo expiry is ruled out.** So is any thermal throttle of the CPU.

**Re-interpretation of run 1.** With hardware throttling eliminated, the shape of run 1's second
half has one clean explanation left. It pinned at *exactly* 60.0 / 59.9 / 60.0 fps across three
consecutive buckets — throttles produce ragged numbers, hard caps produce that — with `MsCPUBusy`
of 16.4 ms sitting right on the 16.67 ms frame budget and `MsGPUBusy` *falling* to 3.0 ms. That is
Fortnite's unfocused / background frame limiter engaging, i.e. **the game lost foreground focus
about 30 seconds into the capture**. Run 1's first 30 seconds (189.8 fps, `MsCPUBusy` 4.9 ms) was
a lighter scene than anything in run 2, which fits a menu or pre-drop state.
**Run 1 is contaminated and must not be used as a comparison baseline. Run 2 replaces it.**
**New protocol rule: never alt-tab, click away from, or minimise the game during a capture.**

**Overall — the authoritative baseline**

| metric | value |
| --- | --- |
| average FPS | **117.8** |
| 1% low | **71.8** |
| 0.1% low | 40.5 |
| peak | 367.2 |
| `MsCPUBusy` / `MsGPUBusy` | **8.14 / 3.86 ms** |
| PresentMode | **`Hardware: Independent Flip`, 100% of 14,128 frames** |
| SyncInterval / AllowsTearing / Runtime | 0 / 1 / DXGI, on every frame |

**T-004 re-confirmed at higher confidence: hard CPU-bound.** CPU busy 8.14 ms against a GPU busy of
3.86 ms and a frametime of 8.49 ms. GPU utilisation ranged 30–51% and never touched its ceiling.
`MsCPUWait` averaged 0.35 ms, so the CPU is not waiting on anything — it is genuinely working.

**Frametime health is good, and the run-1 spikes were warm-up.**

| | run 1 (60 s, 6,996 fr) | run 2 (120 s, 14,128 fr) |
| --- | --- | --- |
| worst frame | **233.5 ms** | **36.2 ms** |
| > 50 ms | 4 | **0** |
| > 33 ms | 11 | **3** |
| > 16.7 ms | 786 (11.2%) | **54 (0.38%)** |
| < 8.3 ms | 4,974 (71%) | 7,504 (53%) |

Nothing in run 2 came close to a stall. The 233 ms and 172 ms freezes in run 1 both landed in the
first 14 seconds and did not recur once the shader cache was warm — which also **closes T-028** as
a live concern. All ten of run 2's worst frames are still pure CPU (`MsCPUBusy` ≈ the whole spike,
GPU 2.8–6.4 ms), so the character of the bottleneck is unchanged; only its severity dropped.

**Per-frame latency — the metrics that actually work here (n=14,128 on every row)**

| metric | avg | p50 | p95 | p99 |
| --- | --- | --- | --- | --- |
| `MsRenderPresentLatency` | 2.74 | 2.38 | 5.07 | 13.64 |
| `MsUntilDisplayed` | 2.74 | 2.38 | 5.07 | 13.64 |
| `MsGPULatency` | 2.39 | 2.03 | 4.70 | 13.28 |
| `MsGPUTime` | 8.49 | 8.19 | 11.47 | 13.85 |
| `MsGPUBusy` | 3.86 | 3.60 | 6.27 | 9.68 |
| `MsCPUBusy` | 8.14 | 7.84 | 11.20 | 13.59 |
| `MsCPUWait` | 0.35 | 0.33 | 0.45 | 0.52 |
| `MsInPresentAPI` | 0.35 | 0.33 | 0.45 | 0.52 |

**Instrument limitation, now confirmed twice — click→photon is not obtainable this way.**
`MsClickToPhotonLatency` is **empty across both runs, 180 seconds total**, and this run was played
with shooting. `MsAllInputToPhotonLatency` collapsed from n=310 in run 1 to **n=2** in run 2
(4.53 and 7.92 ms). Those two facts together are self-consistent and explain each other: run 1's
310 samples came from **menu clicks** during its light opening segment, and once in real gameplay
Fortnite takes aim and fire through **Raw Input**, which PresentMon's ETW input tracking does not
observe on this system. `MsPCLatency` is also empty, so Reflex markers are not reaching PresentMon.
**Consequence: stop chasing click→photon. The A/B yardstick for every future change is
`MsUntilDisplayed` p99 and `MsCPUBusy` p99, both of which are complete on every frame.**
This also revises the T-000g note — PresentMon works, but its input-side metrics do not survive
contact with raw input here. `antimicro` sitting in the input path is a plausible aggravating
factor and is now T-035.

**Thermals re-scored, and T-020 downgraded `[high]` → `[medium]`.** The GPU held a flat
**68–69 °C at 21.2–21.6 W against a 50 W cap**, clocking **988–1307 MHz against 1530 MHz**, and
still reports `SW Power Cap: Active` and `SW Thermal Slowdown: Active`. So the card is genuinely
being governed to roughly 43% of its power budget — but it is *also idle for more than half of
every frame*, so the governor is not what limits output. Meanwhile the CPU sustained full turbo in
the same chassis. Cooling work remains worth doing for long sessions and for the day this stops
being CPU-bound, but it is no longer a top-tier FPS item and the earlier "73 °C at idle" framing
overstated it.

**Backlog re-ordered in this entry.** `02-tweak-backlog.md` rewritten (29,974 B) with a new status
block at the top and the following changes:
- **T-021 background CPU contention promoted to #1** — on a CPU-bound machine this is the mechanism.
- **T-035 `antimicro`** added `[high]` — 2,744 CPU-sec input mapper sitting in the input path.
- **T-036 Process Lasso audit** added `[high]` — it rewrites priority/affinity at runtime and is a
  confound for every CPU number recorded in this project.
- **T-037 3D Resolution 70% → 100%** added `[medium]` — `DesiredScreenWidth=1344` confirms 70%, and
  with 45–51% GPU headroom this should be visually free.
- **T-038 boost mode 4 → 2** added `[low]`, deliberately weak — turbo is already sustained.
- **T-006 frame-cap recommendation formally retracted.** "Cap to 60–70" was wrong here. With
  `SyncInterval 0` and tearing allowed, rendering above refresh lowers displayed latency; capping
  to 60–70 would raise input lag to buy consistency the machine already has. Leave the 160 cap.
- **T-034 mouse DPI promoted** `[low]` → `[medium]` — with render-to-display at 2.74 ms average, the
  ~5 ms available on the device side is now the largest addressable chunk of the chain.
- **T-020 downgraded**, **T-033 downgraded**, **T-003 marked do-not-test**, **T-005 demoted**,
  **T-022 and T-028 marked un-actionable** (no NVIDIA Control Panel is installed on this machine —
  only the bare 596.86 driver, no `Control Panel Client` folder), **T-009 marked blocked** pending
  an explanation for the missing Reflex markers.

- Verdict: the alarming finding from `T-000h` was a measurement artifact, and the honest picture is
  much better than it looked an hour ago. On a 60 Hz panel this machine now delivers a **1% low of
  71.8**, i.e. it is above refresh 99% of the time, with zero frames over 50 ms. **Framerate is no
  longer the problem.** What remains is CPU time per frame, and the input-device end of the latency
  chain, which is bought by spec rather than measured by capture.
- Next: **T-035 (`antimicro`) then T-036 (Process Lasso)** — both are pure CPU-contention items on
  a CPU-bound machine, both are free, and T-036 must happen before any further CPU measurement is
  trustworthy. Then T-037 as a visual win. `01-current-settings.md` and `09-latency-measurement.md`
  are still stale and need the fullscreen / 1080p / cap-160 / 70%-3D-res state and the raw-input
  finding written into them.

---

### T-000j · GPU POWER CEILING FOUND (23 W, not 50 W) + LATENCY ISOLATED TO THE WI-FI LINK
- Date: 2026-08-13, 12:45–12:56
- Type: diagnostic audit. **One temporary, reverted system change** (Windows power-mode slider).
- Trigger: user asked (a) can the GPU be made to work harder, (b) ping still feels like ~30.

#### Part 1 — the GPU is power-capped at 23 W and it is not adjustable

**This corrects a claim made twice in this log and once in the backlog.** `T-000i` said the GPU sat
at "21.4 W against a 50 W cap" with "half its power budget free". That reading was wrong.

| nvidia-smi field | value |
| --- | --- |
| `power.default_limit` | 50.00 W |
| `Requested Power Limit` | 50.00 W |
| **`enforced.power.limit`** | **23.00 W** |
| measured in-game draw | 21.2–21.6 W |

The card was running at **~93% of its actually-enforced budget**, not 43% of a 50 W one. The driver
requests 50 W; the platform grants 23 W. `LITSSVC` (Lenovo Intelligent Thermal Solution Service) and
`IBMPMSVC` are both running and arbitrate a shared CPU+GPU chassis budget — and they are giving it
to the CPU, which holds 137% of base clock. On a CPU-bound game that allocation is defensible.

**Two attempts to raise it, both failed:**
1. `nvidia-smi -pl 50` → `Changing power management limit is not supported for GPU: 00000000:01:00.0`
2. Windows power-mode slider → **Best Performance** (`ded574b5-45a0-4f42-8737-46345c09c238`), which
   on a ThinkPad P15 is documented to invoke Lenovo Ultra Performance Mode. Held 8 seconds with
   Fortnite running. Result: `enforced.power.limit` **unchanged at 23.00 W**, draw 21.4 W, still
   pstate P3. **Reverted to the original position** (`(none set)` → restored to the all-zero default
   GUID, which is the same effective state). No lasting change.

**The thermal narrative was also overstated — third correction on this topic.** Real thresholds:
**GPU Slowdown 92 °C, Shutdown 97 °C, Max Operating 102 °C**, against a measured **68 °C**. The
`SW Thermal Slowdown: Active` flag is the driver's software power policy, not a hardware thermal
event: `HW Thermal Slowdown` = `Not Active` with a lifetime counter of **0 us**. The card has never
hit a real thermal limit. 24 °C of headroom.

**One real GPU lever does exist and was verified:** `nvidia-smi -lgc 1300,1530` succeeded
(*"GPU clocks set to (gpuClkMin 1300, gpuClkMax 1530)"*) and `-rgc` reset cleanly. Logged as T-039.
It cannot add power, only reduce clock variance. PCIe is Gen3 x16, at full width — not a factor.

**Answer to "can the GPU work harder": no, and it would not help.** It is pinned against a firmware
power ceiling, and the frametime is CPU-limited anyway. The useful move is the opposite — spend the
idle GPU *time* on image quality (T-037, 3D Resolution 70% → 100%), which is free.

#### Part 2 — the remaining latency is on the Wi-Fi link, not the ISP

Hop-by-hop to `3.101.95.110` (Epic NA-West), 14-hop trace plus 25-packet idle runs:

| hop | address | RTT |
| --- | --- | --- |
| 1 | `10.0.0.1` (own gateway) | **6 / 6 / 12 ms** |
| 2 | `172.30.28.59` | 19 / 23 / 16 ms |
| 3 | `96.216.234.81` | 17 / 16 / 18 ms |
| 4 | `96.216.129.217` | 16 / 18 / 17 ms |
| 5 | `96.216.129.85` | 21 / 29 / 21 ms |
| 6 | `96.216.129.193` | 19 / 23 / 23 ms |
| 7 | `96.110.41.101` | 22 / 21 / 18 ms |
| 8 | `96.110.33.86` | 22 / 22 / 21 ms |
| 9–14 | ICMP filtered | — |

**The Comcast segment is flat and healthy** — hops 2 through 8 add almost nothing, and the path
never regresses. Destination median 21–23 ms. There is no bad route to fix and no congested hop.

**But hop 1 costs 6 ms, and it should cost under 1 ms.** That is the laptop-to-router leg, over
Wi-Fi. Roughly a quarter of the total round trip is being spent crossing the room.

**And the spikes originate there too.** Idle, unloaded, 25 packets each:
- Epic NA-West: min 18, **max 241**, avg 35 ms — with 241 ms, 88 ms and 68 ms outliers, 0% loss
- Own gateway: min 5, **max 177**, avg 14 ms — 0% loss

A **177 ms spike to your own router on an idle network** cannot be the ISP, cannot be bufferbloat
(fixed in `T-000g`, and this was idle) and cannot be routing. It is the wireless link. A confirming
20-packet run came back clean (4–12 ms, avg 6), which is exactly the signature of Wi-Fi: mostly
fine, intermittently terrible. **This is the best available explanation for "ping ranging around
30"** — the median is ~22 and the spikes are what actually get felt.

Link itself is not the problem: `Wiifii`, 5 GHz ch 157, 802.11ac, 85% signal, Rx 780 / Tx 650 Mbps.
A fresh scan shows it is **the only network in range**, so channel contention and the `xfinitywifi`
public-hotspot airtime theory are both ruled out for this location.

**N-001 (wired Ethernet) promoted to the #1 network item**, and the earlier "do not expect much"
note is retracted. **N-009 added:** ask Xfinity about Low Latency DOCSIS / L4S — live to 10 M+ homes
as of Jan 2026, free, requires an XB7/XB8/XB10 gateway; the current model could not be read over
HTTP and needs to be read off the sticker. Note the pre-existing `Fortnite` QoS policy already marks
DSCP 46, which DOCSIS LLD classifiers can use to select the low-latency queue.

- Verdict: two questions, two clean answers. The GPU is not loafing — it is fenced in at 23 W by
  firmware that no software switch on this machine can move, and freeing it would not raise FPS
  anyway. The network is not slow — the route is at its floor and the remaining addressable latency
  is a 6 ms Wi-Fi hop plus a spike class that only a cable will remove.
- Next: **plug in an Ethernet cable** (N-001) and re-run the 50-packet A/B; read the gateway model
  off its sticker (N-009). On the FPS side nothing changes: T-035 `antimicro`, then T-036.

---

### T-000k · ★★ THE "ULTIMATE PERFORMANCE" POWER PLAN WAS CRIPPLING BOTH THE GPU AND THE CPU
- Date: 2026-08-13, 13:00–13:07
- Type: **applied change, kept.** Biggest single discovery of the project.
- Trigger: user pushed back — *"lets get our ping lower just by config dont worry about stuff we
  cant controll think it thru instead of coping"* — plus approval to pursue the GPU.

#### The finding that invalidates a lot of earlier work

`T-000j` concluded the 23 W GPU cap was firmware-imposed and immovable because `nvidia-smi -pl`
failed and the power slider did nothing. **That conclusion was wrong.** The slider did nothing
*because the machine was on the classic `Ultimate Performance` power plan*, which Lenovo's
Intelligent Thermal Solution (`LITSSVC`) cannot drive on Windows 11. Switching to the modern
`Balanced` plan released everything instantly:

| state | cpuPerf | GPU enforced limit | GPU draw | SM clock | pstate |
| --- | --- | --- | --- | --- | --- |
| A) **Ultimate Performance** | **127%** | **23.00 W** | 21.33 W | **525 MHz** | **P3** |
| B) Balanced, slider default | 138% | **50.00 W** | 31.77 W | **1530 MHz** | **P0** |
| C) Balanced + Best Performance | 147% | 50.00 W | 30.85 W | 1530 MHz | P0 |
| C) after settle | **150%** | 50.00 W | 31.98 W | 1530 MHz | P0 |

**The plan named "Ultimate Performance" was the single worst setting on this machine.** It cost
**27 W of GPU power budget, 1005 MHz of GPU clock, an entire pstate, and ~23 points of CPU turbo.**
`LITSSVC` was clamping everything because it had no modern plan to arbitrate against.

**Consequence: `baseline2` is obsolete as a performance reference.** All 14,128 frames of it were
captured with the GPU fenced at 23 W in P3. It remains valid as a *methodology* reference and as
the "before" row, but a fresh 90 s capture is now required before any further A/B is meaningful.
The CPU-bound conclusion probably survives (8.14 ms CPU vs 3.86 ms GPU is a wide gap) but the GPU
frametime and the 0.1% lows should both improve, and **T-037 (3D Resolution 70% → 100%) just got a
lot more affordable.**

**Also retracts the T-020 rewrite from `T-000j`.** The "platform refuses, nothing you can do"
framing was wrong. Fourth correction to the thermal/power story, and the first one that turned out
to be fixable. Temps rose only 69 °C → 72 °C at more than double the power draw — still 20 °C below
the 92 °C slowdown threshold, so there is room.

#### Network config changes, applied together

Switching to `Balanced` would have *regressed* the network, because `Ultimate Performance` already
had PCIe ASPM off and wireless power saving at maximum performance. Those were re-applied to
`Balanced` defensively before measuring, so they are not the source of the gain.

| # | change | mechanism |
| --- | --- | --- |
| 1 | PCIe ASPM → **Off** on Balanced (AC+DC) | stops the Wi-Fi card's PCIe link entering low-power states |
| 2 | Wireless Power Saving → **Maximum Performance** on Balanced (AC+DC) | parity with the old plan |
| 3 | `netsh int udp set global uro=disabled` | UDP Receive Offload coalesces datagrams; Fortnite is UDP |
| 4 | **MIMO Power Save Mode: `Auto SMPS` → `No SMPS`** | stops the radio parking receive chains and paying a wake cost |

Everything else in the adapter was already optimal and was left alone: Roaming Aggressiveness
`1. Lowest`, Transmit Power `5. Highest`, Packet Coalescing `Disabled`, U-APSD `Disabled`,
Fat Channel Intolerant `Disabled`, Channel Width `Auto`, Preferred Band `Prefer 5GHz`,
`802.11n/ac/ax Wireless Mode` already `4. 802.11ax` (the AP is what limits the link to 802.11ac),
RSC already off on Wi-Fi, WLAN autoconfig left enabled (disabling it risks a non-recovering link).

#### Measured result — idle, 30 packets, same conditions as the `T-000j` baseline

| target | before (T-000j) | after | delta |
| --- | --- | --- | --- |
| Epic NA-West avg | 35 ms | **21 ms** | **−14 ms** |
| Epic NA-West max | **241 ms** | **25 ms** | **−216 ms** |
| Epic NA-West range | 18–241 | **17–25** | spike class gone |
| gateway avg | 14 ms | **7 ms** | **−7 ms** |
| gateway max | **177 ms** | **11 ms** | **−166 ms** |
| packet loss | 0% | 0% | — |

**Tightest distribution ever measured on this machine.** All 30 packets to Epic landed in an 8 ms
band. Every previous idle run had at least one outlier above 60 ms.

**Attribution, honestly:** four changes went in together, so this is an aggregate result.
URO cannot be the cause of the *ICMP* improvement (ping is not UDP), though it may still help the
game. Items 1 and 2 were regression guards, not improvements. **`MIMO Power Save Mode → No SMPS` is
the most likely cause**, with the adapter re-association that the change forced as a real confound.
A single 30-packet sample also cannot prove an intermittent spike class is gone. Re-measure across
several sessions before treating −14 ms as durable.

- Verdict: the ping *was* fixable by config after all, and the biggest lever was a power plan whose
  name implied the opposite of what it did. Retracts the "we're at the floor, buy a cable" framing
  from `T-000j` — the cable is still worth it, but it is no longer the only move.
- Revert commands, if any of this misbehaves:
  - power plan: `powercfg /setactive 5a756bc4-9e68-4a76-a0be-472f967ba946`
  - URO: `netsh int udp set global uro=enabled`
  - MIMO: `Set-NetAdapterAdvancedProperty -Name 'Wi-Fi' -DisplayName 'MIMO Power Save Mode' -DisplayValue 'Auto SMPS'`
- Next: **re-baseline FPS immediately** — `.\measure.ps1 -Seconds 90 -ChangeId T-033 -Scenario A
  -Label balanced-plan-50w`. Then T-037 (3D Resolution to 100%), which the freed GPU now pays for.
  Then T-035 / T-036 on the CPU side. Re-run the idle ping suite next session to confirm durability.

---

### T-000l · Revert prior INI tweaks + apply latency-session in-game checklist + re-apply reverted system settings
- Date: 2026-08-16
- change_id: `T-000l`
- Change: three groups of changes, all reversible.

**Group 1 — Revert prior session's INI tweaks (applied earlier today, 2026-08-16 ~20:12):**
- `LatencyTweak2`: 2 (On+Boost) → **1** (On). Reverts the prior session's edit AND aligns with T-009's
  revised decision: Boost adds up to 5 °C on a single-fan Quadro T1000 at 73 °C idle — ruled out by
  both video corpora.
- Render scale: 80% → **100%** (T-037). `sg.ResolutionQuality` 80→100, `NeverUpscaledResolutionQuality`
  80→100, `DesiredScreenWidth/Height` 1536×864→1920×1080, `LastUserConfirmedDesiredScreenWidth/Height`
  →1920×1080. GPU headroom now pays for full 3D Resolution; below 100% blurs enemy models (AGENTS.md
  hard constraint).
- `FrameRateLimit`: was 360 (prior session set 0, game rewrote back to 360, prior session re-set 0).
  Now **0** (Unlimited) — confirmed live. Session summary item 4: keep Unlimited in-match for best
  latency on this setup.

**Group 2 — Apply latency-session in-game checklist (new changes):**
- `FrontendFrameRateLimit`: 120 → **60**. Lobby/frontend frame cap halved — free heat saving on a
  CPU-bound machine that hits ~92 °C in-match.
- `AudioQualityLevel`: 1 (High) → **0** (Low), `LastConfirmedAudioQualityLevel` → 0. User chose Low
  to save ~1,800 CPU-sec of audiodg time. Trade: reduced footstep clarity.
- Replays: **not applied via INI** — `bRecordReplays`, `bRecordLargeTeamReplays`, `bUsePreloadedReplays`
  are all ABSENT from `GameUserSettings.ini`. These are controlled in-game only (Settings → Game UI →
  Replays). User needs to set them in-game. Flagged as TODO.

**Group 3 — Re-apply system-level tweaks that had silently reverted (same pattern as the 2026-08-16
audit found):**
- Power plan: **Ultimate Performance** → **Balanced** (+ PCIe ASPM off, Wireless max perf on AC/DC).
  This is T-000k's proven recipe. The session summary's stage-1 script applied this at 15:24, but it
  had reverted to Ultimate Performance by 20:21. Re-applied using exact commands from
  `latency-pack\apply-stage1.ps1`.
- `Win32PrioritySeparation`: **38** → **36** (T-032). Had reverted to 38. Re-applied.
- `FN-UploadShaper` QoS policy: throttle was **dead** (empty) → recreated at **10 Mbps**
  (`ThrottleRateAction=10000000` bits/s, registry `ThrottleRate=1250000` bytes/s). The session
  summary's qos-fix.ps1 had the same issue — the `ThrottleRateActionBitsPerSecond` property name
  reads empty in `Get-NetQosPolicy` output, but the actual `ThrottleRateAction` property and the
  registry `Throttle Rate` value both confirm 10 Mbps is live.

**Wi-Fi adapter settings (stage 2) — still live, no re-apply needed:**
- MIMO Power Save Mode: No SMPS ✓
- Packet Coalescing: Disabled ✓
- Roaming Aggressiveness: 1. Lowest ✓
- Preferred Band: 3. Prefer 5GHz ✓

- Reason: User asked to revert the prior session's tweaks and apply the 2026-08-16 latency-session
  summary instead. The session summary's system-level work (power plan, Wi-Fi adapter, QoS, Win32
  PrioritySeparation) was already done by the latency-pack scripts but three of those had silently
  reverted — the same drift pattern the audit found. The in-game checklist items were not yet applied
  to the INI.
- Baseline: not measured this session. Last measured FPS: 117.8 avg / 71.8 1% low (session summary,
  60 Hz panel). Last measured ping: 22.8 ms avg to NA-West, 100 ms max to gateway (pre-fix baseline
  from the session summary's A-arm).
- After: pending re-baseline. Run `measure.ps1 -Seconds 90 -ChangeId T-000l -Scenario A` next session.
  Run `ping-ab.ps1 -Label B-post` to confirm the Wi-Fi spike class stays gone.
- Feel: not yet played.
- Verdict: keep (pending verification)
- Notes:
  - Backup: `backups\revert-apply-20260816-202112\GameUserSettings.ini` (pre-change INI state).
  - INI edits verified by reading back from disk: all 6 changes persisted.
  - System-level edits verified by direct query: power plan GUID, registry DWORD, QoS policy properties.
  - **Cloud-sync caveat (from `pc-tweaks\GAMING.md`):** Fortnite owns `GameUserSettings.ini` and
    reconciles it against cloud-synced settings on launch. An INI edit to the frame cap on 2026-08-13
    was discarded by the game two minutes after launch. After starting Fortnite, open Settings → Video
    and confirm the values stuck; if not, set them in-game.
  - **Replays still need in-game action:** Settings → Game UI → Replays → Off for all three replay
    options. Cannot be done via INI (keys absent).
  - Revert commands:
    - INI: restore from `backups\revert-apply-20260816-202112\GameUserSettings.ini`
    - Power plan: `powercfg /setactive 5a756bc4-9e68-4a76-a0be-472f967ba946` (Ultimate Performance)
    - Win32PrioritySeparation: `Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name Win32PrioritySeparation -Value 38 -Type DWord`
    - QoS: `Remove-NetQosPolicy -Name 'FN-UploadShaper' -PolicyStore 'localhost' -Confirm:$false`

---
