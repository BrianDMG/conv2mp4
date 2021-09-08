#Load properties file
$propFile = Convert-Path "$($env:APP_HOME)\files\prop\properties"
$propRawString = Get-Content "$propFile" | Out-String
$propStringToConvert = $propRawString -replace '\\', '\\'
$prop = ConvertFrom-StringData $propStringToConvert
Remove-Variable -Name propFile, propRawString, propSTringToConvert

#Load configuration
$cfgRawString = Get-Content "$($prop.cfg_path)" | Out-String
$cfgStringToConvert = $cfgRawString -replace '\\', '\\'
$cfg = ConvertFrom-StringData $cfgStringToConvert
Remove-Variable -Name cfgRawString, cfgStringToConvert

$env:VERSION=$prop.version
$env:PLATFORM=$prop.platform
$env:CURRENT_SCHEDULE=$cfg.run_schedule

#Start Pode Server
Start-PodeServer {

    #Define Pode endpoint
    Add-PodeEndpoint -Address $prop.listener_bind_host -Port $prop.listener_port -Protocol $prop.listener_protocol

    Set-PodeViewEngine -Type Pode
    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeViewResponse -Path 'index' -Data @{ prop = "$($prop)"; cfg = "$($cfg)"; }
    }

    #Listener health check
    Add-PodeRoute -Method Get -Path '/health' -ScriptBlock {
        Write-PodeJsonResponse -Value @{ 'value' = "It's alive!" }
    }

    #Manual script execution
    Add-PodeRoute -Method Get -Path '/run' -ScriptBlock {
        Write-Host "$([DateTime]::Now)"
        Write-PodeJsonResponse -Value @{ 'value' = "Executing manual conv2mp4" }
        . "$($env:APP_HOME)/conv2mp4-ps.ps1"
    }

    #Scheduled script execution
    Add-PodeSchedule -Name 'date' -Cron "$($cfg.run_schedule)" -ScriptBlock {
        Write-Host "$([DateTime]::Now)"
        Write-PodeJsonResponse -Value @{ 'value' = "Executing scheduled conv2mp4" }
        . "$($env:APP_HOME)/conv2mp4-ps.ps1"
    }

    #View logs
    #Add-PodeRoute -Method Get -Path '/logs' -ScriptBlock {
    #    Get-Content /log/conv2mp4-ps.log –Wait
    #}

}