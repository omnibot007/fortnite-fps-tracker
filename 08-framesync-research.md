# 08 · FrameSync Labs corpus review (2026-08-13)

Source: `C:\Users\LENOVO\yt_scrapes\framesynclabs\2026-08-13`
Scope: **26 videos, 1 channel (FrameSync Labs), 159,546 chars — read in full.**
Second research round; see `07-video-research.md` for the first.

Nothing in this file has been applied to the machine. Every item is a claim to test,
scored against the measured hardware in `05-hardware.md` and the measured network in
`06-network.md`.

---

## Why this corpus scores higher than the first one

`07-video-research.md` covered 30 videos from 19 channels. Most were tutorials with no
measurements, and at least 9 carried paid placements for tweak suites.

This channel is different in kind. It runs before/after benchmarks with:

- An **LDAT / NVIDIA Reflex latency analyzer** for click-to-photon latency
- **CapFrameX** for FPS and frame times
- **LatencyMon** for interrupt-to-process (DPC/ISR) latency
- A **wall power meter** for total system draw
- **20 consecutive runs** to establish a standard deviation, then an explicit rule:
  **any change under 4% is treated as noise**

That margin-of-error discipline is the one thing missing from the entire first corpus, and
it is why this folder is worth more than its video count suggests.

### Conflicts of interest, stated up front

- **Surfshark VPN sponsors at least 4 of the 26 videos.** Never tied to a performance claim.
- **They sell PC optimization sessions** and close most videos with a pitch.
- **They publish their own custom OS ("FSOS") and their own AME playbook**, Discord-gated.
  Their custom-OS benchmarks therefore rank *their own product* against rivals. Treat that
  whole 4-video cluster as marketing with benchmarks attached.

The tell that they are still mostly honest: **their measurements repeatedly kill tweaks they
could have sold.** They debunk timer resolution, mouse data queue size, USB port choice,
process-count trimming, and registry packs.

---

## What this changes in our own backlog

Five open items move.

### T-023 BIOS thermal/power → **CLOSED, do not do** [high]

"I Disabled ALL Power Saving Features in Windows & BIOS" (100K views) disabled C-states,
ASPM, PSS, PSU idle control, dynamic tick, CPU idle, power throttling and GPU P-states, on
both an Intel and an AMD machine.

Result: **no FPS gain and no input-delay gain** in CS2 or Cyberpunk. The only thing that
moved was interrupt-to-process latency. The cost was **+35% power draw on AMD, up to +70%
on Intel**.

Two quotes decide it for this machine:

> "I'd highly recommend keeping throttle states enabled, especially on laptops or PCs with
> mediocre cooling."

> "If you're using a laptop, I'd only recommend disabling those at your own risk while also
> keeping an eye on your temperatures."

This is a 50 W-capped Quadro T1000 sitting at **73 °C at 26 W near idle**. Trading +35–70%
power draw for zero measured FPS is strictly negative here — the extra heat comes straight
out of the thermal headroom that T-020 exists to protect.

### T-011 process priority → **CLOSED, no effect** [high]

Measured twice: "running the game in High versus normal priority didn't make a big
difference and it's within the margin of error." The 21-ways video opens by listing "set
priority to high" as its example of recycled Windows XP advice.

Caveat worth keeping: it can help *if other background apps run above normal priority*.
That is a background-app problem (T-021), not a priority problem.

This also settles the question asked directly in chat on 2026-08-13.

### T-021 close background clients → **CONFIRMED, and now has a method** [high]

"Low Process Count = More FPS? I Tested It" separates two things the first corpus conflated:

- **Process *count* is irrelevant.** 70 vs 1,000 processes: no difference, on low-end,
  mid-range and high-end machines alike. Trimming process count is wasted effort.
- **Running background *apps* cost 3–9% FPS**, and removing them measured **6–36%**.

Their method, worth copying for our audit:

> Process Explorer → right-click a column header → Select Columns → Process Performance →
> tick **CPU Cycles** and **Context Switch Delta**.

They found >80% of cycles going to RGB software, browsers and recording apps, with Windows'
own processes at the bottom.

Ours already looks heavy from the network audit: `msedge`, Notion, `python`, `devin`,
`node`, `glazewm`, plus `EpicGamesLauncher` / `EpicWebHelper` alongside the game. Measure
rather than guess.

### T-022 NVIDIA control panel profile → **downgrade the generic profile to [low]**

"Do These Best NVIDIA Settings REALLY Give You +500 FPS?" applied a popular NVCP guide and
measured **3.4–4% average FPS at best**, nothing outside noise on 1% lows, and **input lag
that rose by up to 1 ms in some titles**. A second video measured 1.5% average.

Keep the two targeted parts, drop the rest:

- **Shader cache → 10 GB** stays. It targets stutter and 1% lows, which is the metric that
  matters on a 60 Hz panel, and is not what these tests measured.
- **Prefer Maximum Performance** keeps its thermal caveat, now stronger. One of their own
  tests found NVCP *balanced* beat *highest performance*, and locking clocks high on a 50 W
  part spends headroom we do not have.

### T-025 disable VBS → **CLOSED, near no-op here** [high]

Quantified at last: disabling VBS and related security features gained **9.4% on a low-end
PC, 2.2% mid-range, 1.5% high-end** in Fortnite.

But our own audit found `SecurityServicesRunning = {0}` and `HVCI Enabled = 0` — VBS is
configured but **not actually running**, so there is nothing to reclaim.

---

## New items worth adding

Numbering starts at T-032 — `02-tweak-backlog.md` already uses T-031 for the
hardware-accelerated GPU scheduling A/B.

### T-032 · Win32PrioritySeparation → decimal 36 [low]

The channel's only explicitly **non-sponsored** video tested every value from 20–26 and
36–42. Windows 10/11 default is **38**.

- **36** gave the best average FPS and the best 0.2% / 1% lows
- 20 second, 41 third
- **Latency was identical across the whole 20–42 range** (microseconds apart)

A second video measured up to 7.7% on 1% lows at 36. Two other videos in the folder say 40
instead; the 40 advice never comes with benchmarks, the 36 advice does.

Worth trying because it is a single registry DWORD, **no restart needed**, instantly
revertible, and it targets 1% lows. Expectations stay low because their own FPS deltas sit
close to their own 4% noise floor.

### T-033 · Power plan A/B — Ultimate Performance vs Balanced [medium]

Two separate videos: **"balanced versus high performance power plan made absolutely no
difference"**, and a 25-power-plan shootout whose conclusion was that differences are
negligible with no universal winner.

We are on **Ultimate Performance**. On a desktop that is free. On a 50 W-capped laptop
already at 73 °C it may be counterproductive, because it holds clocks and voltage up and
spends thermal budget for no measured FPS return.

Run as a proper A/B/A alongside T-020, judging **sustained** FPS in minutes 5–10 of a
session, not the first 60 seconds.

### T-034 · Raise mouse DPI, lower in-game sens proportionally [low]

From the 21-ways video (545K views, the channel's biggest): **400 → 3200 DPI cut input lag
by about 5 ms**, because it is sensor-side latency. Keep effective sensitivity identical —
at 800 DPI / sens 1, use 1600 / 0.5 or 3200 / 0.25.

Tension to note: `07-video-research.md` recorded pros commonly running 800 DPI. The 5 ms is
real but it is a feel change; test in Creative before ranked.

Free, and larger than every registry tweak in both corpora combined.

---

## Independently confirms what we already measured

### Bufferbloat is the right diagnosis (N-004)

Their most-viewed video (573K) puts **bufferbloat at #3** in what actually affects ping,
names the **Waveform bufferbloat test** we already used, and names **SQM** on the router as
the real fix. Arrived at independently, and it matches `06-network.md` exactly: NA-West ran
**17/21/26 ms under download load but 30/71/122 ms under upload load**, while the gateway
stayed at 3/5/10.

### TCP tweak packs are the wrong protocol

Same video, unprompted:

> "TCP Optimizer... it optimizes the TCP protocol, and games — especially shooter games —
> use UDP... TCP is only used for HTTP connections, patches and possibly voice chat."

Exactly why we rejected the Nagle / `TcpAckFrequency` / MTU family.

### The 60 Hz panel outweighs everything

The clearest number in either corpus: **60 → 240 Hz removes about 12.5 ms of latency**,
while 240 → 540 Hz removes only 2.3 ms. Their blunt summary:

> "Upgrading your PC and peripherals will give you a much bigger latency reduction than any
> tweak out there would."

Also: mouse click latency ranges from ~1 ms to ~8.4 ms between models — an 8 ms spread that
dwarfs every software tweak in this folder.

---

## Killed by measurement — add to "not doing"

| Claim | Measured result |
|---|---|
| **Timer resolution** | 10 games tested. ~0.7% latency change, ≤1% FPS. **Fortnite specifically got slightly *worse* input latency.** |
| **Mouse data queue size** | End-to-end and mouse latency **completely unaffected**. Only polling *consistency* changed. They bricked a mouse setting it too low. |
| **USB port choice** | Difference measured **in microseconds**. And: *"if you have an Intel processor, this wouldn't really matter, since they don't have a port that's direct to the CPU."* This is an Intel machine. |
| **Trimming process count** | 70 vs 1,000 processes: no difference on any of three machines. |
| **Registry tweak packs** | A whole video of them; nothing survived. Nagle's algorithm: no change. |
| **Disabling CPU idle** | *"You might be shooting yourself in the foot and tanking your performance."* Locks the CPU to 100% for no benefit. |
| **Unparking all cores / idle thresholds to 100%** | Their own other video measured **letting Windows manage core parking as 2.5% avg / 3.5% lows better**. Their "60-second DPC fix" contradicts their own benchmarks. |

## Rejected specifically because of this machine

- **Disabling core 0 via Process Lasso.** Measured up to 8% on 1% lows — but their own
  stated prerequisite is **"more than six and preferably eight physical cores."** This CPU
  has **exactly six**. Fails their own rule.
- **Disabling hyperthreading / SMT.** The 17.1% figure came from a many-core desktop chip
  that also had E-cores to disable. 6C/12T → 6 threads for a multi-threaded game.
- **Disabling NIC offload, interrupt moderation and flow control.** Their own caveat:
  *"only recommended for newer and more powerful processors; if you have an older processor,
  please keep offloading enabled."* A 2020 6-core mobile i7 is the case being warned about —
  it moves packet work onto the CPU.
- **Disabling IPv6 / unticking adapter protocol bindings.** No benchmark offered; already
  rejected in the network round.
- **`FastSendDatagramThreshold` registry DWORD.** A real Windows tunable, but presented with
  no before/after. Not worth a registry write without evidence.
- **Chasing NVIDIA driver versions.** ~20 drivers across two videos; most land inside noise,
  latency differences in **microseconds**. Their one real signal — Game Ready beating Studio
  by 8.3% on 1% lows — has no clean Quadro equivalent, since a Quadro runs the professional
  branch by design. This machine is on **596.86**; leave it alone.

## Custom OS / debloat cluster — reject (4 videos)

Headline numbers up to 35%, plus a $0 mini-PC challenge claiming 62%.

Why it does not transfer:

1. **They are ranking their own product.** FSOS is theirs.
2. **Their own disclaimer kills it:** *"if you're heavily CPU or GPU bottlenecked, you might
   not see such huge performance gains."* This is a 4 GB, 50 W GPU. We are GPU-bound.
3. **Their own low-end test was abandoned** because the machine ran "way below 60 FPS" and
   any gain would be "a meaningless amount of like five frames or so."
4. **Anti-cheat.** Their debloat video says plainly: if you play *"Faceit, Valorant, or
   Fortnite tournaments, you should leave the security mitigations enabled — otherwise it
   won't let you play."* Several builds also remove Defender permanently, needing a reinstall
   to undo.

Reinforces the existing rejection of the Windows 23H2/22H2 downgrade advice from
`07-video-research.md`, and adds a concrete anti-cheat reason.

---

## Contradictions inside the channel — do not treat as settled

- **NVIDIA Reflex.** One video: *"setting Nvidia Reflex to off gave us a 2.2% boost on
  average and 7.7% on the 2% lows... keep it off for good."* Another, four months later:
  *"the most optimal way to get the lowest latency is to combine G-Sync, VSync and Reflex +
  Boost."* Same channel, opposite conclusions. T-009 stays an A/B; the Quadro thermal
  argument against **Boost** from `07-video-research.md` still stands independently.
- **Full-screen optimizations.** One video measures **on** as better (1% avg, 2.6% on lows);
  another measures **off** as slightly better on lows. Net: noise. The useful detail is the
  method — it must be set on the **game executable**, not a desktop shortcut, which is the
  common mistake. Related: **windowed borderless measured slightly better 1% / 2% lows with
  no latency penalty**, a reasonable fallback for T-007 if exclusive fullscreen misbehaves.
- **HAGS.** "Improved 1% and 2% lows by up to 2.8%" vs "didn't change anything
  significantly." T-028 stays a real A/B; expect ~2–3% on lows at most, bias toward off.

---

## Bottom line for this machine

The main value of this corpus is **subtractive**: it closes T-011, T-023 and T-025,
downgrades T-022, and independently confirms both the bufferbloat diagnosis and the
rejection of TCP tweak packs.

What it adds is small — one registry value (T-032), one power-plan A/B (T-033), one DPI test
(T-034), and a proper method for the background-app audit (T-021).

What it does not change: **T-001 baseline still has not been run**, and the two confirmed
config bugs — the **923×915 window** (T-007) and the **180 FPS cap** (T-006) on a 60 Hz
panel — remain worth more than everything in both corpora combined.
