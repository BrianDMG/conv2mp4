Function New-Log {

  Param (
    [String]$LogPath,
    [String]$DateFormat
  )

  If ($null -eq $LogPath -OR $null -eq $DateFormat) {
    return $False
  }

  #Date format
  $date = Get-Date -format $DateFormat

  #Generate log
  $prop.paths.files.log = "$($prop.paths.files.log)-$($date).log"

  Write-Version
  Add-Log "$($prop.formatting.standard_divider)"
  Add-Log "$($prop.formatting.standard_indent) New Session (started $($time.Invoke()))`n"

  If (Test-Path $LogPath) {
    return $True
  }
  Else {
    return $False
  }
}