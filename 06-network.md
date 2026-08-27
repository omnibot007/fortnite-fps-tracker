# 06 - Network & Latency

Last updated: 2026-08-13 (audits T-000c, T-000d; fix applied and verified in T-000g)
Player-reported baseline: ~30 ms in-game ping, Fortnite NA-West.

---

## Verdict in one line

The route, the Wi-Fi link, and the region selection are all healthy and at or
near their floor. The one real defect found was **upload-side bufferbloat in the
cable modem**, which tripled ping the moment anything uploaded. **That is now
fixed and verified** - see section 3. Nothing else on this page will move idle
ping, which sits at ~30 ms and is a distance-and-physics floor.

---

## 1. Link & path (measured)

| Item | Value |
|---|---|
| Active link | Wi-Fi (Ethernet I219-V present but media disconnected) |
| Adapter | Intel Wi-Fi 6 AX201 160MHz, driver 24.60.0.3 (2026-06-11) |
| SSID / BSSID | Wiifii / a8:97:cd:2f:9c:26 |
| Band / channel | 5 GHz, ch 157, 802.11ac |
| Signal | -52 dBm (87%) |
| Link rate | Rx 866.7 / Tx 650 Mbps |
| Client IP | 10.0.0.21, gateway 10.0.0.1 |
| ISP | Comcast, hsd1.ca.comcast.net (California) |

Signal and link rate are excellent. Driver is current. No action.

### 5 GHz neighbour survey - CLOSED

`netsh wlan show networks mode=bssid` returned **only Wiifii**. No competing
5 GHz networks are in range at all. Channel congestion is ruled out. Do not
change channel 157. Former item N-005 is dropped.

---

## 2. Matchmaking region - CLOSED, already optimal

50-packet tests against Epic's published regional ping endpoints:

| Region | Endpoint IP | min / avg / max | Loss |
|---|---|---|---|
| **NA-West** | 3.101.95.110 | **17 / 22 / 34 ms** | 0% |
| NA-Central | 18.88.1.169 | 53 / 59 / 66 ms | 0% |
| NA-East | 44.192.142.31 | 78 / 83 / 103 ms | 0% |

NA-West wins by 37 ms over the next best. `GameUserSettings.ini` shows
`"regionId":"NAW"` on every recent selection, so the correct region is **already
selected**. There is no change to make here.

Former item N-003 ("verify region") is resolved. The earlier advice to go and
set the region manually was wrong - it was already right.

### Route to NA-West is clean

```
1  10.0.0.1          2 ms     (gateway)
2  172.30.28.59
3  96.216.234.81              Comcast
4  96.216.129.217
5  96.216.129.85
6  96.216.129.193
7  96.110.41.101
8  96.110.33.86     ~20 ms    (Comcast edge)
9-15  Request timed out
```

**Hops 9-15 timing out is NOT packet loss.** AWS/Epic edge routers suppress
ICMP. The 50-packet test to the destination itself returned **0% loss**. Do not
misread this trace as a problem.

---

## 3. Bufferbloat - THE REAL FINDING

Bufferbloat is latency added by an over-full queue when a link is saturated.
Tested both directions against the NA-West server.

| Condition | NA-West ping | vs idle |
|---|---|---|
| Idle baseline | 17 / 22 / 34 ms | - |
| **Download saturated** | 17 / 21 / 26 ms | **0 ms - clean** |
| **Upload saturated** | **30 / 71 / 122 ms** | **+49 ms avg, +88 ms peak** |

And the key diagnostic - the gateway during that same upload load:

| Target, upload saturated | min / avg / max |
|---|---|
| Gateway 10.0.0.1 | **3 / 5 / 10 ms (unchanged)** |
| NA-West 3.101.95.110 | 30 / 71 / 122 ms |

### What this localises

The gateway answers in 5 ms while internet traffic takes 71 ms. The queue that
is filling is therefore **not** the laptop, **not** the Wi-Fi link, and **not**
the router's LAN side. It is the **cable modem's upstream buffer / Comcast
uplink**. Download direction is clean, so this is upload-only - the classic
cable-modem upstream bufferbloat signature. This would grade D/F on the
Waveform bufferbloat test.

### Why it matters for Fortnite

Anything that uploads while playing spikes ping from ~30 to 70-120 ms:
cloud backup, OneDrive/Dropbox/photo sync, OBS or Twitch streaming, a game
upload or patch seeding, or the always-on `cloudflared` tunnel. This is
intermittent by nature, which is exactly how it would be experienced - ping
that is fine most of the time and then spikes for no visible reason.

### FIXED - 2026-08-13, verified by measurement

**The router-side fix turned out to be unavailable.** The gateway at `10.0.0.1`
was identified: MAC `70-54-25-bb-2f-7d`, HTTP 200,
`Server: Xfinity Broadband Router Server`, `TITLE=XFINITY`. It is a rented
Comcast/Xfinity gateway. It has no SQM, no CAKE, no fq_codel, and no usable
upload shaper. Both YouTube corpora prescribe exactly that fix and it simply
cannot be done here without bridge mode plus a third-party router.

**Client-side shaping was used instead**, on the principle that if this PC never
hands the modem more than the modem can drain, the modem's queue never fills.

True upload capacity was measured first - 3 runs, 20 MB each, to
`speed.cloudflare.com/__up`:

| Run | Seconds | Upload |
|---|---|---|
| 1 | 14.80 | 11.34 Mbps |
| 2 | 14.74 | 11.38 Mbps |
| 3 | 14.62 | 11.48 Mbps |

Remarkably consistent, so **10 Mbps (~88% of line rate)** was chosen as the
shaping target - the 90-95% SQM convention, with extra headroom for DOCSIS
upstream overhead.

```powershell
# applied, elevated:
New-NetQosPolicy -Name 'FN-UploadShaper' -Default `
  -ThrottleRateActionBitsPerSecond 10000000 -PolicyStore 'localhost'

# revert:
Remove-NetQosPolicy -Name 'FN-UploadShaper' -PolicyStore 'localhost' -Confirm:$false

# inspect what is actually live:
Get-ChildItem 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS'
```

### Result - same test, same load, shaper on

| Condition | NA-West ping | Gateway |
|---|---|---|
| Upload saturated, **no shaper** | 30 / **71** / 122 ms | 3 / 5 / 10 ms |
| Upload saturated, **shaper on** | 18 / **24** / 34 ms | 4 / 6 / 9 ms |
| Delta | **-47 ms avg, -88 ms peak** | unchanged |

0% packet loss in both runs. The after-numbers land *at* the idle floor
(17-30 ms, which drifted over the session), so induced latency is now
effectively zero. The gateway never moved, which re-confirms the queue was in
the modem's WAN uplink and not on the LAN.

### Details worth remembering

- **A Fortnite QoS policy already existed** at
  `HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite` -
  `FortniteClient-Win64-Shipping.exe`, `DSCP Value = 46`, `Throttle Rate = -1`.
  Origin unknown; not created by this project. **Leave it alone.** It is
  load-bearing: a more specific app policy outranks the new default policy, so
  Fortnite is exempt from the shaper and gets its own queue instead of sharing a
  bucket with bulk uploads. The DSCP 46 marking is almost certainly ignored by
  Comcast on the WAN, but it costs nothing.
- **Units trap.** `New-NetQosPolicy` takes **bits** per second; the registry
  stores `ThrottleRate` in **bytes** per second. Passing 10000000 wrote
  `1250000`. Always read the key back.
- Prerequisites verified: QoS Packet Scheduler (`ms_pacer`) bound and enabled on
  Wi-Fi, QWAVE service running. Took effect immediately - no reboot, no
  `gpupdate`.
- **Do not throttle `cloudflared.exe` specifically.** It carries the local MCP
  bridge; rate-limiting it causes 502s. The default policy covers it at a rate
  far above what the tunnel needs, which is fine.
- Cost of the fix: bulk uploads cap at 10 Mbps instead of 11.4, about 12%
  slower. Standard SQM trade, worth it.

### Honest scope

This fixed a **latent** vulnerability, not an active everyday defect. OneDrive is
installed but was not running, and the original +49 ms was produced by a
deliberate 3x parallel upload. The payoff comes during Epic patch uploads, cloud
saves, Discord screenshare, OBS streaming and browser uploads. **Idle ping is
unchanged at ~30 ms** and nothing on this page will change that.

Still worth doing regardless, and free: quit sync clients before a session.

**N-004 is CLOSED - fixed and verified.**

---

## 4. Throughput Booster A/B/A - no effect, reverted

Intel's generic guidance recommends Throughput Booster `Disabled` for
latency-sensitive use. Tested properly with an A/B/A to separate the setting
from time-of-day drift:

| State | NA-West avg | Gateway avg |
|---|---|---|
| Enabled (baseline, 50 pkt) | 22 ms (17-34) | 7 ms (5-13) |
| **Disabled** (20 pkt) | 40 ms (17-274); 28 ms excl. one outlier | 7 ms (4-11) |
| Enabled again (25 pkt) | 30 ms (17-52) | 7 ms (6-13) |

**Verdict: no measurable effect.** The gateway is 7 ms in all three runs, so the
local link is untouched by this setting. NA-West drifted 22 -> 28 -> 30 ms
*upward across time regardless of the setting* - the final Enabled run was
slower than the Disabled run. The variance is internet-side, not adapter-side.

**Setting was reverted to `Enabled` (its original value). System left as found.**

Note the drift itself is informative: the NA-West floor moved from 22 ms at
04:15 to 30 ms at 04:38. The player's reported ~30 ms is the honest current
baseline; the 22 ms reading was a favourable earlier window.

---

## 5. Adapter & OS stack - all already correct

Checked against Intel's published recommendations. Everything matches or beats
guidance:

| Setting | Value | Status |
|---|---|---|
| Transmit Power | 5. Highest | correct |
| Preferred Band | 3. Prefer 5GHz | correct |
| Wireless Mode | 4. 802.11ax | correct |
| Channel Width 5 GHz | Auto | correct |
| Roaming Aggressiveness | 1. Lowest | fine for a stationary desk |
| U-APSD | Disabled | correct |
| Packet Coalescing | Disabled | correct |
| Wireless Power Saving | Maximum Performance (AC and DC) | correct |
| NetworkThrottlingIndex | 4294967295 (disabled) | correct |
| TCP autotuning / RSS / ECN | normal / enabled / enabled | sane |

No further adapter tuning is available. This stack is done.

### Delivery Optimization - downgraded to non-issue

No policy key present (default behaviour) and no active transfers. The earlier
suggestion to restrict it was precautionary; measurement shows nothing to fix.

---

## 6. DNS - cosmetic only

| Server | Time to resolve epicgames.com |
|---|---|
| 64.6.64.6 (primary, retired Neustar) | **1847 ms** |
| 8.8.8.8 (secondary) | 32 ms |

The primary is a decommissioned resolver and is very slow. **This does not
affect in-match ping** - gameplay is UDP to an already-resolved IP. It only
affects launcher/menu/login responsiveness. Worth fixing for general snappiness:
set DNS to 1.1.1.1 / 8.8.8.8. `[medium]`, no ping benefit.

---

## 7. Background network consumers

Established connections while Fortnite was open:

| Process | Conns |
|---|---|
| FortniteClient | 9 |
| EpicGamesLauncher | 6 |
| **cloudflared** | **5** |
| Notion | 4 |
| EpicWebHelper | 2 |
| python | 2 |
| msedge | 2 |
| devin | 2 |
| glazewm, node, EpicOnlineServicesUserHelper, aesm_service | 1 each |

`cloudflared` is an always-on tunnel. Given the upload bufferbloat above, it was
the most likely resident source of background upload. It is now covered by the
10 Mbps default shaper, so it can no longer flood the modem's upstream queue.
`[low]`

**Never write a QoS policy that throttles `cloudflared.exe` specifically.** It
carries the local MCP bridge, and rate-limiting it produces 502 errors. The
default policy already covers it at a rate far above what the tunnel needs.

---

## 8. Open network items

| ID | Item | Confidence | Status |
|---|---|---|---|
| N-001 | Wired Ethernet A/B | `[high]` | needs a cable. Revised expectation: ~3-7 ms plus much tighter jitter, not a large mean drop |
| N-002 | Fix slow primary DNS | `[medium]` | menu snappiness only, no ping gain |
| N-004 | ~~Fix upload bufferbloat~~ | - | **CLOSED 2026-08-13. Router SQM was impossible (rented Xfinity gateway), so a 10 Mbps client-side QoS shaper was used instead. Verified: 71 -> 24 ms avg under load. See section 3** |
| N-006 | Wi-Fi 6 / WPA3 capable router | `[low]` | link already runs 802.11ac at 866 Mbps |
| N-003 | ~~Verify matchmaking region~~ | - | CLOSED, already NAW and optimal |
| N-005 | ~~Change Wi-Fi channel~~ | - | DROPPED, no neighbours exist |
| N-007 | ~~Throughput Booster~~ | - | CLOSED, tested A/B/A, no effect, reverted |

---

## 9. Ceiling estimate

Measured floor to Epic NA-West is 17 ms best-case, 22-30 ms typical, over a
clean 8-hop Comcast path with 0% loss. The in-game number will always read a
few ms above raw ICMP because it includes server tick and queue overhead.

**Realistic best outcome: high-20s with much tighter jitter.** The upload
bufferbloat half of that is now done. A cable (N-001) is the only remaining
piece. Sub-20 ms is not reachable from this location on this ISP - that is a
function of physical distance to Epic's NA-West datacentre, and no configuration
changes it.

The honest headline: ping was already near its floor. The win available was
never a lower average, it was **removing the 70-120 ms spikes** caused by upload
saturation - and as of 2026-08-13 those are gone, measured. What remains on the
network side is a cable, and nothing else.
