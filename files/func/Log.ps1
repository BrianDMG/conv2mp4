Function Log {
    Param ([string]$logString)

    $PSDefaultParameterValues = @{'Out-File:Encoding' = 'utf8'}

    Write-Output $logString | Tee-Object -filepath $prop.paths.files.log -Append

}