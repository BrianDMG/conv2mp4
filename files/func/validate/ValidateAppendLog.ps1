#Validate and act on $cfg.logging.append
Function ValidateAppendLog {

  #Check whether log file is empty
  $logEmpty = Get-Content  $prop.paths.files.log

  #Should the log append or clear
  If ($cfg.logging.append -eq $False) {
    Clear-Content $prop.paths.files.log
    PrintVersion
  }
  Elseif ($cfg.logging.append -eq $True -AND $Null -eq $logEmpty) {
    PrintVersion
  }
  Log "$($prop.formatting.standard_divider)"
  Log "$($prop.formatting.standard_indent) New Session (started $($time.Invoke()))"
}