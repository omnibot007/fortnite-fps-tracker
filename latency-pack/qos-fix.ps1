$ErrorActionPreference = 'Continue'
$log = 'C:\Users\LENOVO\fortnite-fps-tracker\latency-pack\qos-fix-results.txt'
function W($s) { Write-Output $s; Add-Content -Path $log -Value $s -Encoding UTF8 }
if (Test-Path $log) { Remove-Item $log }
W ('QOS SHAPER FIX - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

Remove-NetQosPolicy -Name 'FN-UploadShaper' -PolicyStore 'localhost' -Confirm:$false -ErrorAction SilentlyContinue
W 'old policy removed (if present)'

New-NetQosPolicy -Name 'FN-UploadShaper' -Default -ThrottleRateActionBitsPerSecond 10000000 -PolicyStore 'localhost'
W 'policy recreated with -Default -ThrottleRateActionBitsPerSecond 10000000'

$reg = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\FN-UploadShaper' -ErrorAction SilentlyContinue
W ('registry Throttle Rate (bytes/s, expect 1250000): ' + $reg.'Throttle Rate')

W '--- live policy listing ---'
Get-NetQosPolicy -PolicyStore 'localhost' | ForEach-Object {
  W ('  ' + $_.Name + ' | app=' + $_.AppPathNameMatchCondition + ' | throttleBitsPerSec=' + $_.ThrottleRateActionBitsPerSecond + ' | dscp=' + $_.DSCPAction)
}
W 'DONE'
