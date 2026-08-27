# 07 — Video research digest (YouTube scrape)

Source folder: `C:\Users\LENOVO\yt_scrapes\fortnite-tweaks\2026-08-13`
Corpus: 30 videos · 19 channels · 315,502 transcript chars · scraped 2026-08-13 (yt-dlp 2026.07.04)
Reviewed: 2026-08-13

## How to read this file

This is a filter, not a summary. Every claim in the corpus was checked against the **measured**
state of this machine in `05-hardware.md` and `06-network.md`. Advice that is correct in general
but wrong *here* is listed under "Rejected" with the measurement that kills it.

**Treat the transcripts as marketing copy until proven otherwise.** Of the 30 videos, at least 9
carry a paid placement for a tweaking tool or a "ping booster", usually with a discount code.

## Corpus credibility

The folder contains its own rebuttal, which makes it more useful than a normal scrape.

| Video | Channel | Finding |
| --- | --- | --- |
| "I Bought Viral Fortnite TWEAKS (So You Don't Have To)" | FtSdommm | Actually benchmarked the paid tools. **EXM 4/10** — "basically worse than where I was already at". **Paragon 5/10** — FPS locked to 30 on load, input delay *worse*. Hone 8/10. |
| "These Fortnite Optimizations are KILLING Your FPS..." | Lecctron | Applied several popular guides end to end. Net FPS change ≈ zero. Calls Process Lasso "pretty much useless" and one widely-repeated tweak "fully placebo". |
| "I was Wrong About RisxnTweaks" | egø | **Not evidence.** The reviewer states on-camera they are partnered with the vendor and offers a discount code. Discard. |

Note the internal contradiction: Lecctron's debunk video mocks this genre, yet Lecctron's own
565K-view guide in the same folder recommends registry edits with a "23.7% better 1% lows" claim
and no stated methodology. Same channel, opposite epistemics. Trust the measurements, not the
channel.

## Adopted — new items worth testing here

All free, all reversible, all relevant to *this* hardware. Added to `02-tweak-backlog.md`.

| ID | Item | Why it applies to this machine |
| --- | --- | --- |
| T-028 | **NVIDIA shader cache size → 10 GB** (or unlimited) | Named by Lecctron, Xilly and leStripeZ independently. Rationale is sound: a small cache evicts shaders, and re-entering that area re-compiles them mid-match. Targets **stutter and 1% lows**, which is exactly what matters on a 60 Hz panel. |
| T-029 | **Hardware-accelerated GPU scheduling — A/B it** | Moves scheduling work off the CPU. Fortnite is CPU-bound and this is a 6-core mobile chip. Every source says test rather than assume; two note it can *cause* stutter. |
| T-030 | **Audio → Sound Quality: Low** | leStripeZ notes the in-game description itself flags this as performance-affecting. Cheap CPU win. **Trade-off:** Codelife reports pros use High for footstep clarity. Test with 1% lows, decide on audio. |
| T-031 | **Bind "Switch Quick Bar"** to an unused key | Codelife, citing the pro Veno: leaving it *unbound* adds a small input delay when swapping to builds. Zero cost, zero risk. |
| N-008 | **Epic launcher: disable "allow installs during gameplay"**, disable run-at-startup, minimize-to-tray, notifications | **Directly targets the measured defect.** `06-network.md` shows upload saturation triples ping to 71 ms avg / 122 ms peak. A launcher update firing mid-match is exactly that event. Also close the launcher after the game starts — it held 6 open connections during the audit. |

## Adopted — corrections to items already in the backlog

- **T-009 Reflex — revise to "On", not "On + Boost".** Lecctron warns Boost raises GPU temps up to
  5 °C and says verbatim: *"don't use it on an old Quadro graphics card that has a single tiny fan."*
  This machine is a **Quadro T1000, 50 W cap, 73 °C at near-idle**. Risxn separately reports Boost
  costs meaningful FPS. Set Reflex **On**. Do not use On+Boost.
- **T-003 View Distance → Near — downgrade to `[low]`, probably drop.** The corpus contradicts this
  item. Lecctron states view distance now only affects how far *item pickups* render, with no
  effect on players or structures and no measurable FPS cost; Codelife says pros deliberately run
  it *higher* to spot loot earlier. Setting it to Near likely costs visibility for nothing.
- **T-005 Textures → Low + High Resolution Textures off — keep, now with an exact location.**
  Lecctron: textures don't cost FPS "unless you run out of VRAM". On 4 GB that caveat is the whole
  point. The corpus also supplies the precise control T-005 was describing loosely: Epic launcher
  → Fortnite → Options → **uncheck "High Resolution Textures"** (named by Xilly and Flow, both
  specifically for Performance Mode). This was the single best find in the corpus. Verify whether
  it is currently checked.
- **T-002 Record Replays — soften.** Lecctron revises the usual advice: replays mostly hit the SSD,
  so on a modern SSD leave them on if you use them. Still turn off if unused.
- **T-006 Frame cap — corroborated, with a refinement.** The corpus splits on capped vs unlimited,
  but every source that caps says "cap at what you can hold". On 60 Hz that is a 60–70 cap.
  Codelife adds that an external limiter (RTSS) gives better frame pacing than the in-game cap —
  worth testing only after the in-game cap is proven.
- **N-004 bufferbloat — corroborated by NinjSZN**, who recommends router **QoS / gaming mode** and
  reducing competing devices. That is the same fix as the SQM/CAKE recommendation already logged.

## Free and zero-risk, non-performance

Visibility and ergonomics only. No FPS or ping effect, but no downside either: brightness ~125%,
NVIDIA digital vibrance 70–75%, HUD scale ~80%, reticle ammo indicator on, cumulative damage
numbers on, visualize sound effects on, Windows **Enhanced Pointer Precision off** (mouse accel),
Windows playback 48 kHz + exclusive mode, Discord "communications: do nothing".

**Tweak Zone** (3 videos in the corpus) is a **controller-only** aim setting new in Ch7 S3. It is
not a performance feature. Ignore unless playing on controller.

## Rejected — wrong for this machine specifically

| Corpus advice | Measurement that kills it |
| --- | --- |
| Enable XMP / DOCP / EXPO (3+ videos) | Laptop SODIMM. 2933 MT/s **is** the i7-10750H's official max. Nothing to enable. |
| Custom page file ≈ 1.5× RAM (49152 MB) | Measured page file **PeakUsage 468 MB** of a 17408 MB allocation. Would waste ~48 GB of SSD for zero gain. |
| Disable memory compression | 18 GB of 32 GB free. Nothing to compress. |
| Above 4G Decoding + Resizable BAR | Lecctron's own condition is ">4 GB VRAM". This card has **exactly 4 GB**, and ThinkPad P15 Gen 1 BIOS N30ET52W is unlikely to expose ReBar at all. |
| Disable SMT / hyperthreading | Their own rule is "6 cores or fewer → leave on Auto". This is a 6-core chip. No action. |
| Specific NVIDIA driver versions (572.60 / 580.97 / 591.44) via NVCleanInstall | **Wrong driver branch.** Those are GeForce consumer builds. This is a **Quadro T1000 on 596.86**, a professional/RTX-branch driver. Following this would install the wrong branch. |
| Monitor overclock | Panel is **1920×1080 @ 60 Hz, MaxRefreshRate 60**. This is the one lever that would raise the real ceiling, but OC on a ThinkPad internal panel is unlikely to be exposed and is not worth the risk. |
| Cat6/Cat8 cable quality for ping | Already rejected. Lecctron's debunk mocks this correctly — any Cat5e+ is identical at these speeds. |

## Rejected — unsafe, or unsafe-for-Fortnite

- **`TdrLevel = 0` / `TdrDelay` edits (Jinshi).** `TdrLevel=0` **disables GPU timeout detection and
  recovery**. A recoverable driver hang becomes a hard freeze or bugcheck. On a thermally limited
  50 W mobile GPU that already sits at 73 °C, this is the worst possible machine to do it on.
- **Disable Windows Defender + block Windows Update (Risxn).** Presented as routine. It is not.
- **Downgrade to Windows 11 23H2 / Windows 10 22H2 (Risxn).** Reinstalling the OS to chase frames
  on a 60 Hz panel is not a rational trade.
- **"Disable mitigations" (Hone, via Kxng).** Security off for low single-digit percentages, and a
  plausible anti-cheat interaction.
- **MSI Mode Utility v3 / interrupt-mode registry toggling.** Third-party tool writing interrupt
  config; wrong device selection can leave the machine unbootable. Gains unverified anywhere in
  the corpus.
- **Paid tweak suites — Hone, EXM, Paragon, Risxn/Rizen, Ginxy.** The folder's own benchmark video
  scores two of them at 4/10 and 5/10 with *worse* input delay. Also violates this project's
  ground rule 3. Note Ginxy is pitched with an "auto overclocker" on top.
- **Chris Titus WinUtil debloat.** Not malware and genuinely popular, but it applies dozens of
  changes at once, which breaks ground rule 1 (one change per test). If ever used, it must be a
  deliberate, separately-benchmarked event with a restore point — not folded into other testing.

## Rejected — contradicted by our own network measurements

**"Ping boosters" (ExitLag in Lecctron, GearUP in leStripeZ and NinjSZN) — three sponsored
placements, all rejected.** The claims are "40 → 8 ping" and "all the way down to one ping".
That is not physically achievable: a proxy adds a hop, and it cannot beat a clean direct route.
Our measurements: **NA-West 17/22/34 ms, 0% packet loss, clean 8-hop Comcast route, region
already optimal by 37 ms.** There is no bad route here to fix. A booster would add latency.

**DNS change for lower in-match ping (NinjSZN).** Overclaimed. Gameplay is UDP on an established
session — DNS is not consulted. Already logged as N-002: our primary DNS `64.6.64.6` is genuinely
slow (1847 ms lookup) and worth replacing, but that affects **logins and menus only**, not ping.

**`-lanplay` launch argument (NinjSZN).** Described as "an older optimization" that "still helps".
No evidence given, and it is a LAN-oriented flag. Low confidence — not adopted.

## Consensus items already handled

Game Mode on · Ultimate Performance power plan · Memory Integrity / core isolation off ·
V-Sync off · fullscreen over windowed · Performance Mode renderer · meshes low · 3D resolution
stays at 100% unless GPU-bound · show FPS on · Net Debug Stat on · NetworkThrottlingIndex already
disabled (measured `4294967295`) · Ethernet over Wi-Fi · 5 GHz over 2.4 GHz.

One worth flagging: **NVIDIA Control Panel "Low Latency Mode" is irrelevant for Fortnite** — the
in-game Reflex setting overrides it. The corpus argues about On vs Ultra at length for no reason.

## Still unresolved by the corpus

Nothing in 30 videos addresses the two things actually limiting this machine: a **60 Hz panel**
(which caps the useful benefit of every FPS tweak listed) and **sustained thermals on a 50 W-capped
mobile Quadro**. The corpus optimises for 240–480 Hz desktops. Weight its advice accordingly.
