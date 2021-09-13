# Add-Log various session statistics
Function Update-UsageStatistics {

  Param (
    [Int]$Duplicates,
    [Int]$Simple,
    [Int]$Video,
    [Int]$Audio,
    [Int]$Both,
    [Int]$Compliant,
    [Int]$Speed,
    [Int]$Storage
  )

  $stats = $(Get-Content $prop.paths.files.stats | ConvertFrom-Yaml)

  #Process average speed
  If ($Speed -gt 0) {
    $stats.speed = ($stats.speed + $Speed) / 2
    $stats.speed = [Math]::Round($stats.speed, 2)
  }

  #Process storage delta
  If ($Storage -ne 0) {
    $Storage_GB = ($Storage / 1024)
    $stats.storage = ($stats.storage + $Storage_GB)
    $stats.storage = [Math]::Round($stats.storage, 2)
  }

  #Update stats
  $stats.runs = $stats.runs + 1
  $stats.files = $stats.files + $Simple + $Audio + +$Video + $Both
  $stats.audio = $stats.audio + $Audio + $Both
  $stats.video = $stats.video + $Video + $Both
  $stats.container = $stats.container + $Simple
  If ($cfg.logging.use_ignore_list) {
    $stats.ignore = $(Get-Content $prop.paths.files.ignore).Length
  }
  $stats.compliant = $stats.compliant + $Compliant
  $stats.duplicates = $stats.duplicates + $Duplicates

  $stats | ConvertTo-Yaml | Out-File -Encoding utf8 -NoNewLine $prop.paths.files.stats

}