# If new file is larger than old file
Function IfLarger {
    $diffGT = [Math]::Round($fileNew.length - $fileOld.length)/1MB
    $diffGT = [Math]::Round($diffGT, 2)
    Try {
        Remove-Item -LiteralPath $oldFile -Force -ErrorAction Stop
        Log "$($time.Invoke()) $oldFile deleted."

        If ($diffGT -lt 1) {
            $diffGT_KB = ($diffGT * 1024)
            $diffGT_KB = [Math]::Round($diffGT_KB, 2)
            Log "$($time.Invoke()) New file is $($diffGT_KB)KB larger."
        }
        Elseif ($diffGT -gt 1024) {
            $diffGT_GB = ($diffGT / 1024)
            $diffGT_GB = [Math]::Round($diffGT_GB, 2)
            Log "$($time.Invoke()) New file is $($diffGT_GB)GB larger."
        }
        Else {
            Log "$($time.Invoke()) New file is $($diffGT)MB larger."
        }

        $script:diskUsage = $script:diskUsage + $diffGT

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