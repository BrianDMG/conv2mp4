# Log various session statistics
Function FinalStatistics {
    Log "`n$($prop.final_stat_divider)`n"
    #Print total session disk usage changes
    If ($script:diskUsage -gt -1 -AND $script:diskUsage -lt 1) {
        $diskUsage_KB = ($script:diskUsage * 1024)
        $diskUsage_KB = [Math]::Round($diskUsage_KB, 2)
        Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsage_KB)KB"
    }
    Elseif ($script:diskUsage -lt -1024 -OR $script:diskUsage -gt 1024) {
        $diskUsage_GB = ($script:diskUsage / 1024)
        $diskUsage_GB = [Math]::Round($diskUsage_GB, 2)
        Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsage_GB)GB"
    }
    Else {
        $script:diskUsage = [Math]::Round($script:diskUsage, 2)
        Log "$($time.Invoke()) Total cumulative storage difference: $($script:diskUsage)MB"
    }

    #Do some time math to get total script runtime
    $scriptDurStop = (Get-Date)
    $scriptDurTotal = New-TimeSpan -Start $scriptDurStart -End $scriptDurStop

    Log "`n$script:vidDurTotal of video processed in $scriptDurTotal"

    #Do some math/rounding to get session average conversion speed
    Try {
        $avgConv = $script:vidDurTotal.Ticks / $scriptDurTotal.Ticks
        $avgConv = [math]::Round($avgConv, 2)
        Log "Average conversion speed of $($avgConv)x"
    }
    Catch {
        Log "$_"
        Log "No time elapsed."
    }

    Log "`n$($prop.final_stat_divider)"
}