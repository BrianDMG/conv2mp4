# List files in the queue in the log
Function ListFiles {

    If ($fileCount -ge 1) {
        AppendLog
        Log ("`nThere are $fileCount file(s) in the queue:`n")
    }
    Else {
        Write-Host ("`nThere are no files to be converted in $($cfg.mediaPath). Congrats!`n")
        Try {
            Remove-Item $lock -Force -ErrorAction Stop
        }
        Catch {
            Log "$($time.Invoke()) ERROR: $lock could not be deleted. Please delete manually. "
        }
        Exit
    }

    $num = 0

    ForEach ($file in $fileList) {
        $num++
        Log "$($num). $file"
    }
    Log ""
}