# If file size delta exceeds failover threshold, trigger encoding failure
Function Write-EncodeError {

  $fileSizeDelta = [Math]::Round($targetFileCompare.length - $sourceFileCompare.length)/1MB
  $fileSizeDelta = [Math]::Round($fileSizeDelta, 2)

  Try {
    Remove-Item -LiteralPath "$($targetFile)" -Force -ErrorAction Stop
    Add-Log "$($time.Invoke()) EXCEPTION: New file is over $($cfg.conversion.failover_threshold -replace '[.]','')% smaller ($($fileSizeDelta)MB)."
    Add-Log "$($time.Invoke()) $($targetFileRenamed) deleted."
    Add-Log "$($time.Invoke()) FAILOVER: Re-encoding $($sourceFile) with Handbrake."
  }
  Catch {
    Add-Log "$($time.Invoke()) ERROR: $($targetFileRenamed) could not be deleted. Full error below."
    Add-Log $_
  }

}