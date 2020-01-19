# If new file is smaller than old file
Function IfSmaller {
    $diffLT = [Math]::Round($fileOld.length - $fileNew.length)/1MB
    $diffLT = [Math]::Round($diffLT, 2)
    Try {
        Remove-Item -LiteralPath $oldFile -Force -ErrorAction Stop
        Log "$($time.Invoke()) $oldFile deleted."

        If ($diffLT -lt 1) {
            $diffLT_KB = ($diffLT * 1024)
            $diffLT_KB = [Math]::Round($diffLT_KB, 2)
            Log "$($time.Invoke()) New file is $($diffLT_KB)KB smaller."
        }
        Elseif ($diffLT -lt -1024) {
            $diffLT_GB = ($diffLT / 1024)
            $diffLT_GB = [Math]::Round($diffLT_GB, 2)
            Log "$($time.Invoke()) New file is $($diffLT_GB)GB smaller."
        }
        Else {
            Log "$($time.Invoke()) New file is $($diffLT)MB smaller."
        }

        $script:diskUsage = $script:diskUsage - $diffLT

        If ($script:diskUsage -gt -1 -AND $script:diskUsage -lt 1) {
            $diskUsage_KB = ($script:diskUsage * 1024)
            $diskUsage_KB = [Math]::Round($diskUsage_KB, 2)
            Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsage_KB)KB"
        }
        Elseif ($script:diskUsage -lt -1024 -OR $script:diskUsage -gt 1024) {
            $diskUsage_GB = ($script:diskUsage / 1024)
            $diskUsage_GB = [Math]::Round($diskUsage_GB, 2)
            Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsage_GB)GB"
        }
        Else {
            $script:diskUsage = [Math]::Round($script:diskUsage, 2)
            Log "$($time.Invoke()) Current cumulative storage difference: $($script:diskUsage)MB"
        }
    }
    Catch {
        Log "$($time.Invoke()) ERROR: $oldFile could not be deleted. Full error below."
        Log $_
    }
}