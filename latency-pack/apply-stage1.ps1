$ErrorActionPreference = 'Continue'
$log = 'C:\Users\LENOVO\fortnite-fps-tracker\latency-pack\apply-stage1-results.txt'
function W($s) { Write-Output $s; Add-Content -Path $log -Value $s -Encoding UTF8 }
if (Test-Path $log) { Remove-Item $log }
W ('STAGE 1 APPLY - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
W ''

$balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
$subPci   = '501a4d13-42af-4429-9fd1-a8218c268e20'
$aspm     = 'ee12f906-d277-404b-b6da-e5fa1a576df5'
$subWifi  = '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1'
$wifiPwr  = '12bbebe6-58d6-4636-95bb-3217ef867c1a'

W '--- 1. Power plan -> Balanced (T-000k kept state; High performance was unexplained drift) ---'
powercfg /setactive $balanced
# Defensive: PCIe ASPM off, Wireless max performance (AC+DC) so Balanced does not regress Wi-Fi
powercfg /setacvalueindex $balanced $subPci $aspm 0
powercfg /setdcvalueindex $balanced $subPci $aspm 0
powercfg /setacvalueindex $balanced $subWifi $wifiPwr 0
powercfg /setdcvalueindex $balanced $subWifi $wifiPwr 0
powercfg /setactive $balanced
W ('  active scheme now: ' + (powercfg /getactivescheme))
W ''

W '--- 2. Win32PrioritySeparation 38 -> 36 (T-032 arm; FrameSync measured best lows at 36) ---'
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name Win32PrioritySeparation -Value 36 -Type DWord
$v = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl').Win32PrioritySeparation
W ('  Win32PrioritySeparation now: ' + $v)
W ''

W '--- 3. Restore FN-UploadShaper throttle (10 Mbps; value was missing = shaper dead) ---'
Set-NetQosPolicy -Name 'FN-UploadShaper' -ThrottleRateActionBitsPerSecond 10000000 -PolicyStore 'localhost'
$q = Get-NetQosPolicy -Name 'FN-UploadShaper' -PolicyStore 'localhost'
W ('  FN-UploadShaper throttle (bits/s): ' + $q.ThrottleRateActionBitsPerSecond)
$reg = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\FN-UploadShaper'
W ('  registry Throttle Rate (bytes/s, expect 1250000): ' + $reg.'Throttle Rate')
W ''

W '--- 4. Verify UDP Receive Offload still disabled (T-000k) ---'
$u = netsh int udp show global
$u | ForEach-Object { W ('  ' + $_) }
W ''

W '--- 5. GPU state after plan switch (expect enforced 50W, P0) ---'
$g = nvidia-smi --query-gpu=enforced.power.limit,power.draw,clocks.sm,temperature.gpu,pstate --format=csv,noheader
W ('  ' + $g)
W ''
W 'STAGE 1 COMPLETE'
