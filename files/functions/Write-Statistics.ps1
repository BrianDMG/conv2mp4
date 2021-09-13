# Add-Log various session statistics
Function Write-Statistics {

  If ($fileList.Count -ge 1 -AND $cumulativeVideoDuration -ne "00:00:00") {
    Add-Log "`n$($prop.formatting.final_stat_divider)`n"

    #Print total session disk usage changes
    If ($diskUsageDelta -gt -1 -AND $diskUsageDelta -lt 1) {
      $diskUsageDelta_KB = ($diskUsageDelta * 1024)
      $diskUsageDelta_KB = [Math]::Round($diskUsageDelta_KB, 2)
      Add-Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsageDelta_KB)KB"
    }
    Elseif ($diskUsageDelta -lt -1024 -OR $diskUsageDelta -gt 1024) {
      $diskUsageDelta_GB = ($diskUsageDelta / 1024)
      $diskUsageDelta_GB = [Math]::Round($diskUsageDelta_GB, 2)
      Add-Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsageDelta_GB)GB"
    }
    Else {
      $diskUsageDelta = [Math]::Round($diskUsageDelta, 2)
      Add-Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsageDelta)MB"
    }

    #Do some time math to get total script runtime
    $stopScriptTime = (Get-Date)
    $scriptExecutionDuration = New-TimeSpan -Start $startScriptTime -End $stopScriptTime
    $scriptExecutionDurationFormat = $scriptExecutionDuration.ToString()
    $scriptExecutionDurationFormat = $scriptExecutionDurationFormat.Substring(0, $scriptExecutionDurationFormat.IndexOf('.'))

    Add-Log "`n$cumulativeVideoDuration of video processed in $scriptExecutionDurationFormat"

    #Do some math/rounding to get session average conversion speed
    Try {
      $averageConversionRate = $cumulativeVideoDuration.Ticks / $scriptExecutionDuration.Ticks
      $averageConversionRate = [math]::Round($averageConversionRate, 2)
      Add-Log "Average conversion speed of $($averageConversionRate)x`n"
    }
    Catch {
      Add-Log "$_"
      Add-Log "No time elapsed.`n"
    }

    #Print process type totals
    If ($duplicatesDeleted.Count -ge 1) {
      Add-Log "Duplicates deleted: $($duplicatesDeleted.Count)"
    }
    If ($simpleConversion.Count -ge 1) {
      Add-Log "Simple container conversions: $($simpleConversion.Count)"
    }
    If ($videoConversion.Count -ge 1) {
      Add-Log "Video-only encodes: $($videoConversion.Count)"
    }
    If ($audioConversion.Count -ge 1) {
      Add-Log "Audio-only encodes: $($audioConversion.Count)"
    }
    If ($bothConversion.Count -ge 1) {
      Add-Log "Video and audio encodes: $($bothConversion.Count)"
    }
    If ($fileCompliant.Count -ge 1) {
      Add-Log "Compliant files: $($fileCompliant.Count)"
    }

    Add-Log "`n$($prop.formatting.final_stat_divider)"
  }
  Else {
    Write-Output "`nNo video was encoded/converted."
  }

  Update-UsageStatistics -Duplicates $duplicatesDeleted.Count -Simple $simpleConversion.Count -Video $videoConversion.Count -Audio $audioConversion.Count -Both $bothConversion.Count -Compliant $fileCompliant.Count -Speed $averageConversionRate -Storage $diskUsageDelta

}