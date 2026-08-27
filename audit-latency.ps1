$ErrorActionPreference = 'SilentlyContinue'
$out = @()
function W($s) { $script:out += $s }

$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$p = New-Object System.Security.Principal.WindowsPrincipal($id)
W ('Elevated: ' + $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
W ('User: ' + $id.Name)
W ('Time: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
W ''

W '=== GameUserSettings.ini (live) ==='
$f = "$env:LOCALAPPDATA\FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini"
W ('Config exists: ' + (Test-Path $f))
if (Test-Path $f) {
  $pat = 'FullscreenMode|FrameRateLimit|ResolutionSizeX|ResolutionSizeY|DesiredScreenWidth|DesiredScreenHeight|bUseVsync|RenderingMode|AudioQuality|bRecordReplays|bRecordLargeTeam|bUsePreloaded|regionId|LastConfirmed|Preferred'
  Select-String -Path $f -Pattern $pat | ForEach-Object { W ('  ' + $_.Line) }
}
W ''

W '=== Power plan ==='
$active = powercfg /getactivescheme
W ('  ' + $active)
W ''

W '=== Registry checks ==='
$prio = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'
W ('  Win32PrioritySeparation: ' + $prio.Win32PrioritySeparation + ' (stock 38)')
$mmo = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
W ('  NetworkThrottlingIndex: ' + $mmo.NetworkThrottlingIndex + ' (stock 10, disabled 4294967295)')
W ('  SystemResponsiveness: ' + $mmo.SystemResponsiveness + ' (stock 20)')
$gcs = Get-ItemProperty 'HKCU:\System\GameConfigStore'
W ('  GameDVR_Enabled (HKCU): ' + $gcs.GameDVR_Enabled + ' (want 0)')
$gdv = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'
W ('  AppCaptureEnabled: ' + $gdv.AppCaptureEnabled + ' (want 0)')
$gbar = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\GameBar'
W ('  GameBar: AllowAutoGameMode=' + $gbar.AllowAutoGameMode + ' AutoGameModeEnabled=' + $gbar.AutoGameModeEnabled)
$gpu = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
W ('  HwSchMode (HAGS): ' + $gpu.HwSchMode + ' (absent/1=off, 2=on)')
W ''

W '=== QoS policies ==='
$qos = Get-NetQosPolicy -PolicyStore localhost
if ($qos) { $qos | ForEach-Object { W ('  ' + $_.Name + ' | app=' + $_.AppPathNameMatchCondition + ' | throttle=' + $_.ThrottleRateActionBitsPerSecond + ' | dscp=' + $_.DSCPAction) } } else { W '  (none)' }
W ''

W '=== netsh globals ==='
$uro = netsh int udp show global
W '  UDP:'; $uro | ForEach-Object { W ('    ' + $_) }
W ''

W '=== Wi-Fi adapter key properties ==='
$props = Get-NetAdapterAdvancedProperty -Name 'Wi-Fi'
$props | Where-Object { $_.DisplayName -match 'MIMO|Power Save|Roaming|Transmit|Packet Coalescing|U-APSD|Fat Channel|Channel Width|Preferred Band|Throughput' } | ForEach-Object { W ('  ' + $_.DisplayName + ' = ' + $_.DisplayValue) }
W ''

W '=== Wi-Fi link ==='
$wlan = netsh wlan show interfaces
$wlan | Select-String 'SSID|Signal|Radio type|Channel|Receive rate|Transmit rate|State' | ForEach-Object { W ('  ' + $_.Line.Trim()) }
W ''

W '=== Suspect processes (input path / CPU contention) ==='
$names = 'antimicro','ProcessLasso','ProcessGovernor','Discord','EpicGamesLauncher','EpicWebHelper','Notion','msedge','cloudflared','obs64','obs','FortniteClient-Win64-Shipping','RTSS','RTSSHooksLoader','MSIAfterburner'
foreach ($n in $names) {
  $procs = Get-Process -Name $n
  if ($procs) {
    foreach ($pr in $procs) { W ('  RUNNING: ' + $pr.ProcessName + ' pid=' + $pr.Id + ' cpuSec=' + [math]::Round($pr.CPU,1) + ' wsMB=' + [math]::Round($pr.WorkingSet64/1MB)) }
  }
}
W ''
W '=== Fortnite running? ==='
$fn = Get-Process -Name 'FortniteClient-Win64-Shipping'
W ('  Fortnite running: ' + [bool]$fn)

$dest = 'C:\Users\LENOVO\fortnite-fps-tracker\latency-audit-latest.txt'
$out | Out-File -FilePath $dest -Encoding utf8
Write-Output ('Wrote ' + $dest + ' with ' + $out.Count + ' lines')
