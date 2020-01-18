Function Log {
    Param ([string]$logString)
    Write-Output $logString | Tee-Object -filepath $prop.log_path -append
}