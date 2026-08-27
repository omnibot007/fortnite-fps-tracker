$ErrorActionPreference = 'Continue'
$ts = '20260816-latency'
$dest = "C:\Users\LENOVO\fortnite-fps-tracker\backups\$ts"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

# Registry exports
reg export 'HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl' "$dest\prioritycontrol.reg" /y
reg export 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' "$dest\systemprofile.reg" /y
reg export 'HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS' "$dest\qos-policies.reg" /y

# Power plan
powercfg /getactivescheme | Out-File "$dest\active-scheme-before.txt" -Encoding utf8
powercfg /qh SCHEME_CURRENT | Out-File "$dest\scheme-detail-before.txt" -Encoding utf8

# Wi-Fi adapter properties
Get-NetAdapterAdvancedProperty -Name 'Wi-Fi' | Select-Object DisplayName, DisplayValue, RegistryKeyword, RegistryValue | Export-Csv "$dest\wifi-adapter-before.csv" -NoTypeInformation

# netsh globals
netsh int udp show global | Out-File "$dest\udp-globals-before.txt" -Encoding utf8

# Fortnite config
$fn = "$env:LOCALAPPDATA\FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini"
if (Test-Path $fn) { Copy-Item $fn "$dest\GameUserSettings.ini.bak" -Force }

Write-Output "Backup complete: $dest"
Get-ChildItem $dest | ForEach-Object { Write-Output ('  ' + $_.Name + ' (' + $_.Length + ' bytes)') }
