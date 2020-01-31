# If new file is smaller than old file
Function CompareIfSmaller {
    $deltaLT = [Math]::Round($sourceFileCompare.length - $targetFileCompare.length)/1MB
    $deltaLT = [Math]::Round($deltaLT, 2)
    Try {
        Remove-Item -LiteralPath $sourceFile -Force -ErrorAction Stop
        Log "$($time.Invoke()) $sourceFile deleted."
        Log "$($time.Invoke()) $targetFileRenamed created."

        If ($deltaLT -lt 1) {
            $deltaLT_KB = ($deltaLT * 1024)
            $deltaLT_KB = [Math]::Round($deltaLT_KB, 2)
            Log "$($time.Invoke()) New file is $($deltaLT_KB)KB smaller."
        }
        Elseif ($deltaLT -lt -1024) {
            $deltaLT_GB = ($deltaLT / 1024)
            $deltaLT_GB = [Math]::Round($deltaLT_GB, 2)
            Log "$($time.Invoke()) New file is $($deltaLT_GB)GB smaller."
        }
        Else {
            Log "$($time.Invoke()) New file is $($deltaLT)MB smaller."
        }

        $script:diskUsageDelta = $script:diskUsageDelta - $deltaLT

        If ($script:diskUsageDelta -gt -1 -AND $script:diskUsageDelta -lt 1) {
            $diskUsageDelta_KB = ($script:diskUsageDelta * 1024)
            $diskUsageDelta_KB = [Math]::Round($diskUsageDelta_KB, 2)
            Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsageDelta_KB)KB"
        }
        Elseif ($script:diskUsageDelta -lt -1024 -OR $script:diskUsageDelta -gt 1024) {
            $diskUsageDelta_GB = ($script:diskUsageDelta / 1024)
            $diskUsageDelta_GB = [Math]::Round($diskUsageDelta_GB, 2)
            Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsageDelta_GB)GB"
        }
        Else {
            $script:diskUsageDelta = [Math]::Round($script:diskUsageDelta, 2)
            Log "$($time.Invoke()) Current cumulative storage difference: $($script:diskUsageDelta)MB"
        }
    }
    Catch {
        Log "$($time.Invoke()) ERROR: $sourceFile could not be deleted. Full error below."
        Log $_
    }
}