Function AppendLog {
    #Check whether log file is empty
    $logEmpty = Get-Content $prop.log_path

    #Should the log append or clear
        If ($cfg.appendLog -eq $False) {
            Clear-Content $prop.log_path
            PrintVersion
        }
        Elseif ($cfg.appendLog -eq $True -AND $logEmpty -eq $Null) {
            PrintVersion
        }
        Else {
            Log "`n$($prop.standard_divider)"
            Log "$($prop.standard_indent) New Session (started $($time.Invoke()))"
        }
}