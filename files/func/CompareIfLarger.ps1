# If new file is larger than old file
Function CompareIfLarger {
    $deltaGT = [Math]::Round($targetFileCompare.length - $sourceFileCompare.length)/1MB
    $deltaGT = [Math]::Round($deltaGT, 2)
    Try {
        Remove-Item -LiteralPath $sourceFile -Force -ErrorAction Stop
        Log "$($time.Invoke()) $sourceFile deleted."

        If ($deltaGT -lt 1) {
            $deltaGT_KB = ($deltaGT * 1024)
            $deltaGT_KB = [Math]::Round($deltaGT_KB, 2)
            Log "$($time.Invoke()) New file is $($deltaGT_KB)KB larger."
        }
        Elseif ($deltaGT -gt 1024) {
            $deltaGT_GB = ($deltaGT / 1024)
            $deltaGT_GB = [Math]::Round($deltaGT_GB, 2)
            Log "$($time.Invoke()) New file is $($deltaGT_GB)GB larger."
        }
        Else {
            Log "$($time.Invoke()) New file is $($deltaGT)MB larger."
        }

        $script:diskUsageDelta = $script:diskUsageDelta + $deltaGT

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