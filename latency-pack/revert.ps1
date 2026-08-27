$ErrorActionPreference = 'Continue'
$log = 'C:\Users\LENOVO\fortnite-fps-tracker\latency-pack\revert-results.txt'
function W($s) { Write-Output $s; Add-Content -Path $log -Value $s -Encoding UTF8 }
if (Test-Path $log) { Remove-Item $log }
W ('REVERT - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$bak = 'C:\Users\LENOVO\fortnite-fps-tracker\backups\20260816-latency'

W '--- 1. Registry restore (PriorityControl + QoS) ---'
reg import "$bak\prioritycontrol.reg"
reg import "$bak\qos-policies.reg"

W '--- 2. Power plan back to pre-session state (High performance) ---'
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
W ('  active scheme now: ' + (powercfg /getactivescheme))

W '--- 3. Wi-Fi adapter back ---'
$targets = @(
  @{ Name = 'MIMO Power Save Mode';   Value = 'Auto SMPS' },
  @{ Name = 'Packet Coalescing';      Value = 'Enabled' },
  @{ Name = 'Roaming Aggressiveness'; Value = '3. Medium' },
  @{ Name = 'Preferred Band';         Value = '1. No Preference' }
)
foreach ($t in $targets) {
  try { Set-NetAdapterAdvancedProperty -Name 'Wi-Fi' -DisplayName $t.Name -DisplayValue $t.Value -ErrorAction Stop; W ('  ' + $t.Name + ' -> ' + $t.Value + ' OK') }
  catch { W ('  ' + $t.Name + ' FAILED: ' + $_.Exception.Message) }
  Start-Sleep -Milliseconds 500
}
W ''
W 'REVERT COMPLETE'
