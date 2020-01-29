# If failover encoding fails, log failure
Function PrintEncodeFailure {
    $fileSizeDelta = [Math]::Round($targetFileCompare.length - $sourceFileCompare.length)/1MB
    $fileSizeDelta = [Math]::Round($fileSizeDelta, 2)

    Try {
        Remove-Item $targetFile -Force -ErrorAction Stop
        Log "$($time.Invoke()) Deleted new file and retained $sourceFile."

        Switch($failureCause) {
            corruptCodec {
                Log "$($time.Invoke()) ERROR: File is corrupt (either audio or video codec is unobtainable). $targetFile deleted."
            }
            encodeFailure {
                Log "$($time.Invoke()) ERROR: Failover threshold exceeded even after failover: ($($fileSizeDelta)MB). $targetFile deleted."
            }
        }
    }
    Catch {
        Log "$($time.Invoke()) ERROR: $targetFile could not be deleted. Full error below."
        Log $_
    }
}