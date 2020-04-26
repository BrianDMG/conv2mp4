# If file size delta exceeds failover threshold, trigger encoding failure
Function PrintEncodeError {
    $fileSizeDelta = [Math]::Round($targetFileCompare.length - $sourceFileCompare.length)/1MB
    $fileSizeDelta = [Math]::Round($fileSizeDelta, 2)
    Try {
        Remove-Item -LiteralPath $targetFile -Force -ErrorAction Stop
        Log "$($time.Invoke()) EXCEPTION: New file is over $($cfg.failover_threshold -replace '[.]','')% smaller ($($fileSizeDelta)MB)."
        Log "$($time.Invoke()) $targetFileRenamed deleted."
        Log "$($time.Invoke()) FAILOVER: Re-encoding $sourceFile with Handbrake."
    }
    Catch {
        Log "$($time.Invoke()) ERROR: $targetFileRenamed could not be deleted. Full error below."
        Log $_
    }
}