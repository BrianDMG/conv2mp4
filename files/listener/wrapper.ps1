$scriptPath = Join-Path $env:APP_HOME conv2mp4.ps1
$scriptPath = Convert-Path $scriptPath

#Output logs to docker logs
pwsh /c $scriptPath *> /proc/1/fd/1