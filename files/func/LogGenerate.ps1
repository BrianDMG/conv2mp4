Function LogGenerate {
  Param (
    [String]$LogPath,
    [String]$DateFormat
  )

  #Date format
  $date = Get-Date -format $DateFormat

  #Generate log
  $prop.paths.files.log = "$($prop.paths.files.log)-$($date).log"

  PrintVersion
  Log "$($prop.formatting.standard_divider)"
  Log "$($prop.formatting.standard_indent) New Session (started $($time.Invoke()))"
}