param(
  [Parameter(Mandatory=$true)][string]$Label,
  [Parameter(Mandatory=$true)][string]$OutFile
)
$ErrorActionPreference = 'SilentlyContinue'
$a = Test-Connection -ComputerName 3.101.95.110 -Count 30
$b = Test-Connection -ComputerName 10.0.0.1 -Count 30
$sa = ($a | Measure-Object -Property ResponseTime -Average -Minimum -Maximum)
$sb = ($b | Measure-Object -Property ResponseTime -Average -Minimum -Maximum)
$r = @()
$r += ($Label + ' ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$r += ('NA-West 3.101.95.110: n=' + $sa.Count + ' min=' + $sa.Minimum + ' avg=' + [math]::Round($sa.Average,1) + ' max=' + $sa.Maximum)
$r += ('Gateway 10.0.0.1:   n=' + $sb.Count + ' min=' + $sb.Minimum + ' avg=' + [math]::Round($sb.Average,1) + ' max=' + $sb.Maximum)
$r += 'NA-West raw: ' + (($a | ForEach-Object { $_.ResponseTime }) -join ',')
$r += 'Gateway raw: ' + (($b | ForEach-Object { $_.ResponseTime }) -join ',')
$r | Out-File $OutFile -Encoding utf8
$r | ForEach-Object { Write-Output $_ }
