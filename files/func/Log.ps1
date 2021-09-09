Function Log {
    Param ([string]$logString)
    Write-Output $logString | Tee-Object -filepath  $prop.paths.files.log -Append
}