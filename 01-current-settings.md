# 01 — Current settings baseline

Last reviewed: 2026-08-13 (system-side rows verified by direct query — see `05-hardware.md`)
Status legend: `SET` = confirmed · `TODO` = not applied yet · `?` = unconfirmed, needs a look

## Video

| Setting | Target | Status | Notes |
| --- | --- | --- | --- |
| Rendering Mode | Performance (Alpha) | SET | The big one. Already active. Disables most rendering features to cut CPU + GPU load. |
| Window Mode | Fullscreen | SET | `FullscreenMode=0`. Verified 2026-08-16. |
| Resolution | 1920x1080 | SET | Matches the panel's native resolution. |
| Frame Rate Limit | Unlimited (in-match) / 60 (lobby) | SET | `FrameRateLimit=0` (Unlimited in-match, best latency per session summary); `FrontendFrameRateLimit=60` (lobby, was 120 — heat saving). T-000l. |
| V-Sync | Off | SET | `bUseVSync=False`. Verified 2026-08-16. |
| Motion Blur | Off | SET | `bMotionBlur=False`. Verified 2026-08-16. |
| Show FPS | On | SET | `bShowFPS=True`. Verified 2026-08-16. |

## Graphics quality (what Performance Mode still exposes)

Performance Mode hides most quality sliders because it forces them off. These usually remain:

| Setting | Target | Status | Notes |
| --- | --- | --- | --- |
| View Distance | Near | TODO | Affects environment objects only — enemy players stay visible at Near. |
| 3D Resolution | 100% | SET | `sg.ResolutionQuality=100`, `DesiredScreenWidth=1920` × `DesiredScreenHeight=1080`. Was 80% (1536×864), raised to 100% per T-037/T-000l. GPU headroom now pays for it. |
| Textures | Low | SET | `sg.TextureQuality=0`. Verified 2026-08-16. |
| Auto-download high-res textures | Off | TODO | Avoids loading assets Performance Mode will not use. |
| Anti-Aliasing / Super Resolution | Off | SET | `FortAntiAliasingMethod=Disabled`, `sg.AntiAliasingQuality=0`. Verified 2026-08-16. |

## Game / gameplay

| Setting | Target | Status | Notes |
| --- | --- | --- | --- |
| Record Replays | Off | TODO | Keys absent from INI — must be set in-game: Settings → Game UI → Replays. T-000l flagged. |
| Record Large Team Replays | Off | TODO | Same — in-game only. |
| Preloaded Replays | Off | TODO | Same — in-game only. |
| Visualize Sound Effects | Personal call | ? | Small UI render cost. Keep it if the audio info is worth more than 1-2 frames. |

## Cosmetics (yes, really)

| Item | Target | Status | Notes |
| --- | --- | --- | --- |
| Skin | Simple, non-animated | TODO | Animated / reactive skins and particle-heavy back blings measurably cost frames. |
| Back bling | No particle effects | TODO | |
| Wrap | Plain, non-animated | TODO | Animated wraps render every frame the weapon is on screen. |
| Pickaxe | Plain | TODO | Same logic, on screen constantly while moving. |

## System-side (verified 2026-08-13)

| Item | Target | Status | Notes |
| --- | --- | --- | --- |
| Windows power plan | Balanced (+ ASPM off, wireless max perf) | SET | Re-applied 2026-08-16 T-000l. Was Ultimate Performance (reverted from session summary's Balanced). T-000k's proven recipe — GPU stays at 50W/P0 on Balanced. |
| Memory Integrity (HVCI) | Off | SET | Confirmed off. |
| Secure Boot | **On** | SET | Must stay on — Fortnite requires Secure Boot + TPM 2.0 on Windows 11. |
| Page file | System-managed | SET | 17 GB, peak usage 468 MB. Leave alone. |
| RAM configuration | Dual channel | SET | 2 x 16 GB, ChannelA + ChannelB. Nothing to improve. |
| On AC power while gaming | Yes | SET | Confirmed plugged in. |
| GPU driver | 596.86 | SET | 32.0.15.9686, installed 2026-08-12, verified after 2026-08-13 reboot. |
| Windows Game DVR / background recording | Off | SET | `GameDVR_Enabled=0`, `AppCaptureEnabled=0`. Verified 2026-08-16. |
| NVIDIA Reflex | On (not On+Boost) | SET | `LatencyTweak2=1`. T-009 revised: Boost adds 5°C on single-fan Quadro — ruled out. T-000l reverted prior On+Boost. |
| Audio Quality | Low | SET | `AudioQualityLevel=0`. Was High (1). User chose Low to save ~1,800 CPU-sec audiodg time. T-000l. |
| Win32PrioritySeparation | 36 | SET | Registry DWORD=36. T-032 (FrameSync best 1% lows). Re-applied 2026-08-16 (had reverted to 38). |
| FN-UploadShaper QoS | 10 Mbps | SET | `ThrottleRateAction=10000000` bits/s. Bufferbloat fix (N-004). Re-applied 2026-08-16 (throttle was dead). |
| Wi-Fi: MIMO Power Save | No SMPS | SET | T-000k. Eliminates Wi-Fi spike class. Verified live 2026-08-16. |
| Wi-Fi: Packet Coalescing | Disabled | SET | Reduces receive latency. Verified live 2026-08-16. |
| Wi-Fi: Roaming Aggressiveness | 1. Lowest | SET | Verified live 2026-08-16. |
| Wi-Fi: Preferred Band | Prefer 5GHz | SET | Verified live 2026-08-16. |
| Background GPU clients closed | Yes | TODO | Epic Launcher, Epic overlay, browsers, Electron apps. See T-021. |
| Epic Games Launcher overlay | Disabled | TODO | Was running at audit time. |
| VBS | Off | TODO | Currently enabled and running with zero security services. See T-025. |
| Thermals | Managed | TODO | 73 °C GPU at near-idle. The real limiter. See T-020. |

## Explicitly rejected

| Idea | Why not |
| --- | --- |
| Disabling Secure Boot | Fortnite will not launch on Windows 11 without it. |
| "Dedicating" RAM to Fortnite | No such mechanism for native Windows games. 18 GB already free. |
| XMP / RAM speed tuning | No XMP in ThinkPad BIOS; 2933 is the CPU's official limit and the factory spec. |
| Buying more RAM | 32 GB installed, no memory pressure whatsoever. |
| Disabling the page file | Peak usage 468 MB. Costs nothing, disabling causes crashes. |
| `Engine.ini` `[SystemSettings]` cvar overrides | Largely blocked, ignored, or reset by patches. |
| Third-party "FPS booster" / tweak injectors | Anti-cheat ban risk. |
| Marking config files read-only | Causes settings corruption and silent resets. |
| 3D Resolution below 100% | Destroys enemy readability for a modest frame gain. |
