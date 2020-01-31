# Log various session statistics
Function PrintStatistics {
    If ($fileCount -ge 1) {
        Log "`n$($prop.final_stat_divider)`n"
        #Print total session disk usage changes
        If ($script:diskUsageDelta -gt -1 -AND $script:diskUsageDelta -lt 1) {
            $diskUsageDelta_KB = ($script:diskUsageDelta * 1024)
            $diskUsageDelta_KB = [Math]::Round($diskUsageDelta_KB, 2)
            Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsageDelta_KB)KB"
        }
        Elseif ($script:diskUsageDelta -lt -1024 -OR $script:diskUsageDelta -gt 1024) {
            $diskUsageDelta_GB = ($script:diskUsageDelta / 1024)
            $diskUsageDelta_GB = [Math]::Round($diskUsageDelta_GB, 2)
            Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsageDelta_GB)GB"
        }
        Else {
            $script:diskUsageDelta = [Math]::Round($script:diskUsageDelta, 2)
            Log "$($time.Invoke()) Total cumulative storage difference: $($script:diskUsageDelta)MB"
        }

        #Do some time math to get total script runtime
        $stopScriptTime = (Get-Date)
        $scriptExecutionDuration = New-TimeSpan -Start $startScriptTime -End $stopScriptTime
        $scriptExecutionDurationFormat = $scriptExecutionDuration.ToString()
        $scriptExecutionDurationFormat = $scriptExecutionDurationFormat.Substring(0, $scriptExecutionDurationFormat.IndexOf('.'))
        
        Log "`n$script:cumulativeVideoDuration of video processed in $scriptExecutionDurationFormat"

        #Do some math/rounding to get session average conversion speed
        Try {
            $averageConversionRate = $script:cumulativeVideoDuration.Ticks / $scriptExecutionDuration.Ticks
            $averageConversionRate = [math]::Round($averageConversionRate, 2)
            Log "Average conversion speed of $($averageConversionRate)x"
        }
        Catch {
            Log "$_"
            Log "No time elapsed."
        }

        Log "`n$($prop.final_stat_divider)"
    }
}