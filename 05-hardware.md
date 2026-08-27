# 05 — Hardware and system state

Detected 2026-08-13 by querying the machine directly. Not user-reported — these are measured values.

## The machine

| Component | Value |
| --- | --- |
| Model | Lenovo ThinkPad P15 Gen 1 (machine type 20SU, full model 20SUS34900) |
| Class | Mobile **workstation**, not a gaming laptop. This matters — see below. |
| BIOS | N30ET52W (1.35), released 2023-08-08 |
| OS | Windows 11 Pro, build 26200 |
| CPU | Intel Core i7-10750H — 6 cores / 12 threads, 2.6 GHz base, Comet Lake-H, 45W class |
| GPU | NVIDIA Quadro T1000, 4 GB GDDR5, driver 596.86, **50 W power cap** |
| RAM | 32 GB = 2 x 16 GB Samsung M471A2K43DB1-CWE, dual channel (ChannelA-DIMM1 + ChannelB-DIMM1) |
| RAM speed | Sticks rated 3200 MT/s, running at **2933** — this is correct, see note below |
| Display | 1920 x 1080 @ **60 Hz** (max reported refresh: 60) |
| Page file | C:\pagefile.sys, 17 GB, system-managed. Peak usage ever: 468 MB |
| Power plan | Ultimate Performance (already set) |
| Power state | On AC, battery 95% |
| Secure Boot | ON |
| VBS | Enabled and running, zero security services active |
| Memory Integrity (HVCI) | OFF (already) |

## Measured thermal state

GPU was at **73 °C drawing 26 W of its 50 W cap at 30% utilisation** — with no game being actively
played, just desktop apps plus Fortnite sitting in the background. That is a hot idle. On this
chassis, sustained clocks are decided by cooling headroom long before they are decided by settings.

## Four conclusions that should drive every future recommendation

### 1. The 60 Hz panel is the real ceiling
Frames above ~60 are invisible on this display. They still reduce input latency slightly, but the
goal here is **a stable, flat 60 with clean frametimes**, not a bigger average FPS number. Any tweak
that raises the average from 90 to 110 has changed nothing the user can perceive. Optimise 1% lows
and frametime consistency instead.

### 2. VRAM is the scarce resource, not system RAM
4 GB on the T1000, and roughly 1 GB was already consumed by desktop, browser, Notion, and Epic
overlay processes before Fortnite even started. This is why Textures Low and
"auto-download high-res textures Off" matter more on this machine than on a typical rig, and why
closing background GPU clients is worth real frames rather than being placebo.

### 3. System RAM is a solved problem — stop looking at it
32 GB total, ~18 GB free at measurement time, page file peak usage of 468 MB across the machine's
entire uptime history. There is no memory pressure of any kind. The 2933 MT/s speed is **not a
misconfiguration**: the i7-10750H's memory controller officially tops out at DDR4-2933, and this
exact 2x16GB 2933 configuration is how the P15 shipped from the factory. There is no XMP option in
ThinkPad BIOS and nothing to recover here.

### 4. Thermals and the 50 W GPU cap are the actual limiter
A T1000 is roughly GTX 1650-class silicon in a workstation chassis tuned for quiet sustained
professional loads, not burst gaming. Cooling work (vents, fan cleaning, cooling pad, rear
elevation, repaste if out of warranty) will outperform any remaining in-game toggle for *sustained*
framerate. The first 60 seconds of a match are not the problem; minute 15 is.

## Do not touch

- **Secure Boot must stay ON.** Fortnite requires Secure Boot and TPM 2.0 on Windows 11. Disabling
  it in BIOS as a "performance tweak" will lock the user out of the game entirely.
- **Do not disable the page file.** Peak usage is 468 MB; it costs nothing and disabling it causes
  hard crashes when something does need it.
- **Do not try to "allocate" RAM to Fortnite.** No such mechanism exists for native Windows games.
