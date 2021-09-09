# Log various session statistics
Function UpdateUsageStatistics {

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
  }

  #Process storage delta
  If ($Storage -ne 0) {
    If ($Storage -gt -1 -AND $Storage -lt 1) {
      $Storage_KB = ($Storage * 1024)
      $Storage_KB = [Math]::Round($Storage_KB, 2)
      $Storage_MB = ($Storage_KB * 1024)
      $Storage = ($Storage_MB * 1024)
    }
    Elseif ($Storage -lt -1024 -OR $Storage -gt 1024) {
        $Storage_GB = ($Storage / 1024)
        $Storage = [Math]::Round($Storage_GB, 2)
    }
    Else {
        $Storage_MB = [Math]::Round($Storage, 2)
        $Storage = ($Storage_MB * 1024)
    }

    $stats.storage = ($stats.storage + $Storage)
  }

  #Update stats
  $stats.runs = $stats.runs + 1
  $stats.files = $stats.files + $Simple + $Audio + +$Video + $Both
  $stats.audio = $stats.audio + $Audio + $Both
  $stats.video = $stats.video + $Video + $Both
  $stats.container = $stats.container + $Simple
  $stats.ignore = $(Get-Content $prop.paths.files.ignore).Length
  $stats.compliant = $stats.compliant + $Compliant
  $stats.duplicates = $stats.duplicates + $Duplicates

  $stats | ConvertTo-Yaml | Out-File -Encoding utf8 -NoNewLine $prop.paths.files.stats

}