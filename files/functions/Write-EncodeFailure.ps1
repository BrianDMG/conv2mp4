# If failover encoding fails, log failure
Function Write-EncodeFailure {

  $fileSizeDelta = [Math]::Round($targetFileCompare.length - $sourceFileCompare.length)/1MB
  $fileSizeDelta = [Math]::Round($fileSizeDelta, 2)

  Try {
    Switch($failureCause) {
      corruptCodec {
        $script:corruptFiles += @($sourceFile)
        Add-Log "$($time.Invoke()) ERROR: File is corrupt and will not be processed."
        Add-Log "$($time.Invoke()) Aborted encoding and logged the failure."
        Add-Log "$($time.Invoke()) $($sourceFile) retained."
      }

      encodeFailure {
        $script:failedEncodes += @($sourceFile)
        Remove-Item $targetFile -Force -ErrorAction Stop
        Add-Log "$($time.Invoke()) ERROR: Failover threshold exceeded even after failover: ($($fileSizeDelta)MB)."
        Add-Log "$($time.Invoke()) $($targetFileRenamed) deleted."
        Add-Log "$($time.Invoke()) Deleted new file and retained $($sourceFile)."
      }
    }
  }
  Catch {
    Add-Log "$($time.Invoke()) ERROR: $($targetFile) could not be deleted. Full error below."
    Add-Log $_
  }

}