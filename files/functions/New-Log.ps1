<<<<<<< HEAD:files/functions/GenerateLog.ps1
Function GenerateLog {
=======
Function New-Log {

>>>>>>> feature-rename-methods:files/functions/New-Log.ps1
  Param (
    [String]$LogPath,
    [String]$DateFormat
  )

  #Date format
  $date = Get-Date -format $DateFormat

  #Generate log
  $prop.paths.files.log = "$($prop.paths.files.log)-$($date).log"

  Write-Version
  Add-Log "$($prop.formatting.standard_divider)"
  Add-Log "$($prop.formatting.standard_indent) New Session (started $($time.Invoke()))`n"

}