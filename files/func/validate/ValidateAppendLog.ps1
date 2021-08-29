#Validate and act on $cfg.append_log
Function ValidateAppendLog {

  #Check whether log file is empty
  $logEmpty = Get-Content $prop.log_path

  #Should the log append or clear
  If ($cfg.append_log -eq $False) {
    Clear-Content $prop.log_path
    PrintVersion
  }
  Elseif ($cfg.append_log -eq $True -AND $Null -eq $logEmpty) {
    PrintVersion
  }
  Log "$($prop.standard_divider)"
  Log "$($prop.standard_indent) New Session (started $($time.Invoke()))"
}