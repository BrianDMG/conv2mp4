# If new file is over 25% smaller than the original file, trigger encoding failure
Function FailureDetected {
    $diffErr = [Math]::Round($fileNew.length - $fileOld.length)/1MB
    $diffErr = [Math]::Round($diffErr, 2)
    Try {
        Remove-Item -LiteralPath $newFile -Force -ErrorAction Stop
        Log "$($time.Invoke()) EXCEPTION: New file is over 25% smaller ($($diffErr)MB). $newFile deleted."
        Log "$($time.Invoke()) FAILOVER: Re-encoding $oldFile with Handbrake."
    }
    Catch {
        Log "$($time.Invoke()) ERROR: $newFile could not be deleted. Full error below."
        Log $_
    }
}