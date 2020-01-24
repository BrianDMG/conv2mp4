# If new file is over 25% smaller than the original file, trigger encoding failure
Function PrintEncodeError {
    $fileSizeDelta = [Math]::Round($targetFileCompare.length - $sourceFileCompare.length)/1MB
    $fileSizeDelta = [Math]::Round($fileSizeDelta, 2)
    Try {
        Remove-Item -LiteralPath $targetFile -Force -ErrorAction Stop
        Log "$($time.Invoke()) EXCEPTION: New file is over 25% smaller ($($fileSizeDelta)MB). $targetFile deleted."
        Log "$($time.Invoke()) FAILOVER: Re-encoding $sourceFile with Handbrake."
    }
    Catch {
        Log "$($time.Invoke()) ERROR: $targetFile could not be deleted. Full error below."
        Log $_
    }
}