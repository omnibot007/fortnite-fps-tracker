<#
  measure.ps1 v2 - Fortnite framerate + INPUT LATENCY + THERMAL/CLOCK capture
  ---------------------------------------------------------------------------
  Uses PresentMon 2.3.1, which ships bundled inside RivaTuner Statistics
  Server (already installed on this machine). PresentMon is ETW-based and
  runs OUT OF PROCESS - it does not inject into the game, which is why it
  is considered safe to use alongside Easy Anti-Cheat. Do not replace this
  with an injecting overlay tool.

  v2 CHANGE (2026-08-13): the T-001 baseline showed a hard PERFORMANCE CLIFF
  at t=30s (175 fps -> 60 fps, CPU time per frame 5.3ms -> 16.4ms, GPU busy
  FALLING 4.5ms -> 3.0ms). That signature is either Intel PL2->PL1 turbo
  expiry (power/thermal) or a scene change, and the v1 harness could not
  tell them apart. v2 now samples CPU '% Processor Performance' (actual
  clock vs nominal - >100 means turbo, <100 means throttled) plus GPU
  temp/power/clock once per second alongside the frame capture, and prints
  a 10-second bucket table so the cliff is visible and attributable.

  WHAT IT MEASURES:
    MsClickToPhotonLatency    mouse click -> photons on screen (NEEDS CLICKS)
    MsAllInputToPhotonLatency any input   -> photons on screen
    MsPCLatency               Reflex-reported PC latency
    MsRenderPresentLatency    render submit -> present
    MsBetweenPresents         frametime (used for FPS + 1% lows)
    PresentMode               composition path (windowed vs fullscreen)
    % Processor Performance   CPU turbo/throttle state  [v2]
    GPU temp / power / clock  thermal headroom          [v2]

  USAGE - from an ELEVATED PowerShell:
     cd C:\Users\LENOVO\fortnite-fps-tracker
     .\measure.ps1 -Seconds 90 -ChangeId T-001 -Scenario A -Label baseline

  Launch it, then ALT-TAB into Fortnite and play. Countdown is -Delay (8s).

  IMPORTANT:
   1. Fortnite must be in the FOREGROUND and actively rendering.
      A minimized Fortnite presents zero frames and you get no data.
   2. To get click-to-photon numbers you must actually SHOOT during the
      capture. Movement alone only populates all-input-to-photon.
   3. Run at least 90s. The 60s default in v1 only just caught the cliff.
#>

param(
    [int]$Seconds     = 90,
    [int]$Delay       = 8,
    [string]$ChangeId = 'T-000',
    [string]$Scenario = 'A',
    [string]$Label    = 'unlabeled'
)

$ErrorActionPreference = 'Stop'

$pm = 'C:\Program Files (x86)\RivaTuner Statistics Server\Plugins\Client\PresentMonDataProvider\PresentMon-2.3.1-x64.exe'
if (-not (Test-Path $pm)) { throw "PresentMon not found at: $pm" }

$nvsmi = 'C:\Windows\System32\nvidia-smi.exe'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Must be run from an ELEVATED PowerShell (PresentMon needs admin for ETW).' }

$root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $root 'measurements'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$stamp  = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$csv    = Join-Path $outDir ("{0}__{1}__{2}.csv" -f $stamp, $ChangeId, $Label)
$telCsv = Join-Path $outDir ("{0}__{1}__{2}__telemetry.csv" -f $stamp, $ChangeId, $Label)

Write-Host ''
Write-Host '=================================================' -ForegroundColor Cyan
Write-Host " change_id : $ChangeId"
Write-Host " scenario  : $Scenario"
Write-Host " label     : $Label"
Write-Host " duration  : $Seconds s"
Write-Host '=================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'REMINDER: to get click-to-photon you must SHOOT during the capture.' -ForegroundColor Magenta
Write-Host ''
Write-Host "ALT-TAB INTO FORTNITE NOW - recording starts in $Delay seconds" -ForegroundColor Yellow
for ($i = $Delay; $i -gt 0; $i--) { Write-Host "  $i..." -NoNewline; Start-Sleep -Seconds 1; Write-Host "`r" -NoNewline }
Write-Host ''
Write-Host "RECORDING for $Seconds seconds - play normally." -ForegroundColor Green

# ---------- v2: background telemetry sampler ----------
$telJob = Start-Job -ScriptBlock {
    param($dur, $nvsmiPath)
    $lines = New-Object System.Collections.Generic.List[string]
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $dur) {
        $t = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        $perf = -1
        try {
            $perf = [math]::Round((Get-Counter '\Processor Information(_Total)\% Processor Performance' -MaxSamples 1 -ErrorAction Stop).CounterSamples[0].CookedValue, 1)
        } catch { $perf = -1 }
        $g = 'NA,NA,NA,NA'
        try {
            if (Test-Path $nvsmiPath) {
                $g = ((& $nvsmiPath --query-gpu=temperature.gpu,power.draw,clocks.sm,utilization.gpu --format=csv,noheader,nounits) | Select-Object -First 1) -replace '\s', ''
            }
        } catch { $g = 'NA,NA,NA,NA' }
        $lines.Add("$t,$perf,$g")
        Start-Sleep -Milliseconds 250
    }
    return $lines
} -ArgumentList $Seconds, $nvsmi

& $pm --process_name FortniteClient-Win64-Shipping.exe `
      --output_file $csv `
      --timed $Seconds `
      --terminate_after_timed `
      --stop_existing_session `
      --no_console_stats | Out-Null

$tel = @()
try {
    $telRaw = Receive-Job $telJob -Wait -ErrorAction SilentlyContinue
    Remove-Job $telJob -Force -ErrorAction SilentlyContinue
    if ($telRaw) {
        'elapsed_s,cpu_perf_pct,gpu_temp_c,gpu_power_w,gpu_clock_mhz,gpu_util_pct' | Set-Content -Path $telCsv -Encoding ASCII
        $telRaw | Add-Content -Path $telCsv -Encoding ASCII
        $tel = Import-Csv $telCsv
    }
} catch { }

if (-not (Test-Path $csv)) {
    Write-Host ''
    Write-Host 'NO DATA CAPTURED.' -ForegroundColor Red
    Write-Host 'Fortnite presented zero frames. It must be in the FOREGROUND and rendering.'
    Write-Host 'A minimized or alt-tabbed-away Fortnite produces nothing.'
    exit 1
}

$rows = Import-Csv $csv
if ($rows.Count -lt 10) { Write-Host "Only $($rows.Count) frames captured - too few to trust." -ForegroundColor Red; exit 1 }

function Get-Nums($rows, $col) {
    $out = New-Object System.Collections.Generic.List[double]
    foreach ($r in $rows) {
        $v = $r.$col
        if ($null -ne $v -and $v -ne '' -and $v -ne 'NA') {
            $d = 0.0
            if ([double]::TryParse($v, [ref]$d)) { if ($d -gt 0) { $out.Add($d) } }
        }
    }
    return $out
}

function Get-Pctl($sorted, [double]$p) {
    if ($sorted.Count -eq 0) { return $null }
    $i = [math]::Ceiling(($p / 100.0) * $sorted.Count) - 1
    if ($i -lt 0) { $i = 0 }
    if ($i -ge $sorted.Count) { $i = $sorted.Count - 1 }
    return $sorted[$i]
}

function Show-Metric($rows, $col, $friendly) {
    $v = Get-Nums $rows $col
    if ($v.Count -eq 0) {
        Write-Host ("  {0,-26} not reported" -f $friendly) -ForegroundColor DarkGray
        return
    }
    $s   = [double[]]($v | Sort-Object)
    $avg = ($v | Measure-Object -Average).Average
    Write-Host ("  {0,-26} avg {1,7:N2}   med {2,7:N2}   p95 {3,7:N2}   p99 {4,7:N2}   n={5}" -f `
        $friendly, $avg, (Get-Pctl $s 50), (Get-Pctl $s 95), (Get-Pctl $s 99), $v.Count)
}

# ---------- framerate ----------
$ft = Get-Nums $rows 'MsBetweenPresents'
$ftSorted = [double[]]($ft | Sort-Object)
$avgFt  = ($ft | Measure-Object -Average).Average
$avgFps = if ($avgFt -gt 0) { 1000.0 / $avgFt } else { 0 }
$low1   = 1000.0 / (Get-Pctl $ftSorted 99)
$low01  = 1000.0 / (Get-Pctl $ftSorted 99.9)
$maxFps = 1000.0 / $ftSorted[0]

Write-Host ''
Write-Host '================ FRAMERATE ================' -ForegroundColor Cyan
Write-Host ("  frames captured            {0}" -f $ft.Count)
Write-Host ("  average FPS                {0:N1}" -f $avgFps)
Write-Host ("  1% low FPS                 {0:N1}" -f $low1)   -ForegroundColor Yellow
Write-Host ("  0.1% low FPS               {0:N1}" -f $low01)
Write-Host ("  peak FPS                   {0:N1}" -f $maxFps)

Write-Host ''
Write-Host '================ LATENCY (ms) ================' -ForegroundColor Cyan
Show-Metric $rows 'MsClickToPhotonLatency'    'click -> photon'
Show-Metric $rows 'MsAllInputToPhotonLatency' 'any input -> photon'
Show-Metric $rows 'MsPCLatency'               'Reflex PC latency'
Show-Metric $rows 'MsRenderPresentLatency'    'render -> present'
Show-Metric $rows 'MsUntilDisplayed'          'present -> displayed'
Show-Metric $rows 'MsGPUBusy'                 'GPU busy'
Show-Metric $rows 'MsCPUBusy'                 'CPU busy'

if ((Get-Nums $rows 'MsClickToPhotonLatency').Count -eq 0) {
    Write-Host '  NOTE: no click samples. You did not shoot. Re-run and fire during capture.' -ForegroundColor Magenta
}

# ---------- composition path (T-007 evidence) ----------
Write-Host ''
Write-Host '================ PRESENT PATH ================' -ForegroundColor Cyan
$rows | Group-Object PresentMode | Sort-Object Count -Descending | ForEach-Object {
    $pct = 100.0 * $_.Count / $rows.Count
    Write-Host ("  {0,-42} {1,5:N1}%" -f $_.Name, $pct)
}
Write-Host '  ---'
Write-Host '  "Composed: Flip" means the DESKTOP COMPOSITOR is in the path (windowed).'
Write-Host '  "Hardware: Independent Flip" is the low-latency path you want.'
$sync = $rows | Group-Object SyncInterval | ForEach-Object { "$($_.Name)x$($_.Count)" }
Write-Host ("  SyncInterval: {0}   AllowsTearing: {1}" -f ($sync -join ' '), (($rows | Group-Object AllowsTearing | ForEach-Object { "$($_.Name)x$($_.Count)" }) -join ' '))

# ---------- v2: 10-second buckets + cliff detection ----------
Write-Host ''
Write-Host '================ 10s BUCKETS (watch for a cliff) ================' -ForegroundColor Cyan
Write-Host '   t     fps   1%low   cpuBusy  gpuBusy | cpuPerf%  gpuC  gpuW  gpuMHz'
$bucketFps = @()
$rows | Group-Object { [math]::Floor([double]$_.TimeInMs / 10000) } | Sort-Object { [int]$_.Name } | ForEach-Object {
    $b   = $_.Group
    $t0  = [int]$_.Name * 10
    $bft = [double[]]($b | ForEach-Object { [double]$_.MsBetweenPresents } | Sort-Object)
    $baf = ($bft | Measure-Object -Average).Average
    $bf  = if ($baf -gt 0) { 1000.0 / $baf } else { 0 }
    $bl  = 1000.0 / (Get-Pctl $bft 99)
    $bc  = ($b | ForEach-Object { [double]$_.MsCPUBusy } | Measure-Object -Average).Average
    $bg  = ($b | ForEach-Object { [double]$_.MsGPUBusy } | Measure-Object -Average).Average
    $bucketFps += $bf

    $tw = $tel | Where-Object { [double]$_.elapsed_s -ge $t0 -and [double]$_.elapsed_s -lt ($t0 + 10) }
    $cp = '   -'; $gt = '  -'; $gw = '  -'; $gc = '   -'
    if ($tw -and $tw.Count -gt 0) {
        $v = $tw | Where-Object { [double]$_.cpu_perf_pct -gt 0 }
        if ($v) { $cp = '{0,5:N0}' -f (($v | ForEach-Object { [double]$_.cpu_perf_pct } | Measure-Object -Average).Average) }
        $v = $tw | Where-Object { $_.gpu_temp_c -ne 'NA' }
        if ($v) {
            $gt = '{0,4:N0}' -f (($v | ForEach-Object { [double]$_.gpu_temp_c }  | Measure-Object -Average).Average)
            $gw = '{0,4:N0}' -f (($v | ForEach-Object { [double]$_.gpu_power_w } | Measure-Object -Average).Average)
            $gc = '{0,5:N0}' -f (($v | ForEach-Object { [double]$_.gpu_clock_mhz } | Measure-Object -Average).Average)
        }
    }
    Write-Host ("  {0,3}s  {1,6:N1}  {2,6:N1}  {3,7:N2}  {4,7:N2} | {5}    {6}  {7}  {8}" -f $t0, $bf, $bl, $bc, $bg, $cp, $gt, $gw, $gc)
}

if ($bucketFps.Count -ge 3) {
    $first = $bucketFps[0]
    $last  = $bucketFps[$bucketFps.Count - 1]
    if ($last -lt ($first * 0.75)) {
        Write-Host ''
        Write-Host ('  !! PERFORMANCE CLIFF: {0:N0} fps -> {1:N0} fps ({2:N0}% drop)' -f $first, $last, (100 * (1 - $last / $first))) -ForegroundColor Red
        Write-Host '     If cpuPerf% also fell, this is CPU power/thermal throttling (PL2->PL1),'
        Write-Host '     not a scene change. Fix = cooling / power limits, not graphics settings.'
    }
}

# ---------- v2: worst frametime spikes ----------
Write-Host ''
Write-Host '================ WORST 10 SPIKES ================' -ForegroundColor Cyan
$rows | Sort-Object { -[double]$_.MsBetweenPresents } | Select-Object -First 10 | ForEach-Object {
    Write-Host ("  t={0,6:N1}s   {1,7:N1} ms   cpuBusy {2,7:N1}   gpuBusy {3,6:N1}" -f `
        ([double]$_.TimeInMs / 1000), [double]$_.MsBetweenPresents, [double]$_.MsCPUBusy, [double]$_.MsGPUBusy)
}
Write-Host '  (cpuBusy ~= the spike value means the CPU stalled; gpuBusy high means the GPU did)'

# ---------- GPU vs CPU bound (T-004) ----------
$gpuBusy = Get-Nums $rows 'MsGPUBusy'
$cpuBusy = Get-Nums $rows 'MsCPUBusy'
if ($gpuBusy.Count -gt 0 -and $cpuBusy.Count -gt 0) {
    $g = ($gpuBusy | Measure-Object -Average).Average
    $c = ($cpuBusy | Measure-Object -Average).Average
    Write-Host ''
    Write-Host '================ BOUND BY ================' -ForegroundColor Cyan
    Write-Host ("  avg GPU busy {0:N2} ms   avg CPU busy {1:N2} ms   frametime {2:N2} ms" -f $g, $c, $avgFt)
    if ($g -gt ($avgFt * 0.92)) { Write-Host '  -> GPU BOUND (GPU busy ~= frametime)' -ForegroundColor Yellow }
    elseif ($c -gt ($avgFt * 0.92)) { Write-Host '  -> CPU BOUND - lowering graphics settings will NOT help' -ForegroundColor Yellow }
    else { Write-Host '  -> neither pegged; likely frame-capped or waiting' -ForegroundColor Yellow }
}

# ---------- ready-to-paste benchmarks.csv row ----------
$c2p    = Get-Nums $rows 'MsClickToPhotonLatency'
$c2pAvg = if ($c2p.Count -gt 0) { ($c2p | Measure-Object -Average).Average } else { 0 }
$inp    = Get-Nums $rows 'MsAllInputToPhotonLatency'
$inpMed = if ($inp.Count -gt 0) { Get-Pctl ([double[]]($inp | Sort-Object)) 50 } else { 0 }
$note   = "click2photon_avg=" + ("{0:N2}" -f $c2pAvg) + "ms; input2photon_p50=" + ("{0:N2}" -f $inpMed) + "ms; frames=" + $ft.Count + "; csv=" + (Split-Path -Leaf $csv)
$row    = '{0},{1},{2},{3},{4},{5:N1},{6:N1},{7:N1},,,{8}' -f `
          (Get-Date -Format 'yyyy-MM-dd'), $Scenario, $ChangeId, $Label, '', $avgFps, $low1, $maxFps, $note

Write-Host ''
Write-Host '========= PASTE INTO benchmarks.csv =========' -ForegroundColor Green
Write-Host $row
Write-Host ''
Write-Host "raw frame data: $csv" -ForegroundColor DarkGray
if (Test-Path $telCsv) { Write-Host "telemetry     : $telCsv" -ForegroundColor DarkGray }
Write-Host ''
