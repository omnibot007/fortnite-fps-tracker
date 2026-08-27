$ErrorActionPreference = 'Continue'
$log = 'C:\Users\LENOVO\fortnite-fps-tracker\latency-pack\apply-stage2-results.txt'
function W($s) { Write-Output $s; Add-Content -Path $log -Value $s -Encoding UTF8 }
if (Test-Path $log) { Remove-Item $log }
W ('STAGE 2 APPLY (Wi-Fi adapter - brief re-association expected) - ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
W ''

$targets = @(
  @{ Name = 'MIMO Power Save Mode';   Value = 'No SMPS';            Was = 'Auto SMPS' },
  @{ Name = 'Packet Coalescing';      Value = 'Disabled';           Was = 'Enabled' },
  @{ Name = 'Roaming Aggressiveness'; Value = '1. Lowest';          Was = '3. Medium' },
  @{ Name = 'Preferred Band';         Value = '3. Prefer 5GHz band'; Was = '1. No Preference' }
)

foreach ($t in $targets) {
  W ('--- ' + $t.Name + ': ' + $t.Was + ' -> ' + $t.Value + ' ---')
  try {
    Set-NetAdapterAdvancedProperty -Name 'Wi-Fi' -DisplayName $t.Name -DisplayValue $t.Value -ErrorAction Stop
    W '  set OK'
  } catch {
    W ('  SET FAILED: ' + $_.Exception.Message)
  }
  Start-Sleep -Milliseconds 500
}
W ''
W '--- Verification read-back ---'
Start-Sleep -Seconds 3
Get-NetAdapterAdvancedProperty -Name 'Wi-Fi' | Where-Object { $_.DisplayName -match 'MIMO|Packet Coalescing|Roaming|Preferred Band' } | ForEach-Object { W ('  ' + $_.DisplayName + ' = ' + $_.DisplayValue) }
W ''
W '--- Link state ---'
netsh wlan show interfaces | Select-String 'SSID|Signal|Radio type|Channel|Receive rate|Transmit rate|State' | ForEach-Object { W ('  ' + $_.Line.Trim()) }
W ''
W 'STAGE 2 COMPLETE'
