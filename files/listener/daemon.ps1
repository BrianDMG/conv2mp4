#Load properties file
$propFile = Convert-Path "$($env:APP_HOME)/files/prop/properties.yaml"
$prop = Get-Content "$propFile" | ConvertFrom-Yaml
Remove-Variable -Name propFile

#Load configuration
$cfgFile = Convert-Path "$($prop.paths.files.cfg)"
$cfg = Get-Content "$cfgFile" | ConvertFrom-Yaml
Remove-Variable -Name cfgFile

$env:USAGE_STATISTICS = $prop.paths.files.stats
$env:LOG_PATH = $prop.paths.files.logDir

#Start Pode Server
Start-PodeServer {

    #Define Pode endpoint
    Add-PodeEndpoint -Address $prop.listener.bind_host -Port $prop.listener.port -Protocol $prop.listener.protocol

    Set-PodeViewEngine -Type Pode

    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        $logs = $(Get-ChildItem -Path $env:LOG_PATH -Recurse -Include *.log | Sort-Object -Descending -Property LastWriteTime -Top 10)
        $stats = $(Get-Content $env:USAGE_STATISTICS | ConvertFrom-Yaml)
        Write-PodeViewResponse -Path 'index' -Data @{ prop = $using:prop; cfg = $using:cfg; logs = $logs; stats = $stats; }
    }

    #Listener health check
    Add-PodeRoute -Method Get -Path '/health' -ScriptBlock {
        Write-PodeJsonResponse -Value @{ 'value' = "It's alive!" }
    }

    #Manual script execution
    Add-PodeRoute -Method Get -Path '/run' -ScriptBlock {
        Use-PodeScript -Path ./wrapper.ps1
    }

    #Scheduled script execution
    Add-PodeSchedule -Name 'date' -Cron "$($cfg.schedule.run_schedule)" -ScriptBlock {
        Write-Host "$([DateTime]::Now)"
        . "$($env:APP_HOME)/conv2mp4.ps1"
    }

    #View logs
    Add-PodeRoute -Method Get -Path '/logs' -ScriptBlock {
        $logs = $(Get-ChildItem -Path $env:LOG_PATH -Recurse -Include *.log | Sort-Object -Descending -Property LastWriteTime)
        Write-PodeViewResponse -Path 'logs' -Data @{ prop = $using:prop; logs = $logs; }
    }

}