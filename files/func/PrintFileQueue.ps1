# List files in the queue in the log
Function PrintFileQueue {

    If ($fileCount -ge 1) {
        AppendLog
        Log ("`nThere are $fileCount file(s) in the queue:`n")
    }
    Else {
        Write-Output ("`nThere are no files to be converted in $($cfg.mediaPath). Congrats!`n")
    }

    $num = 0

    ForEach ($file in $fileList) {
        $num++
        Log "$($num). $file"
    }
    Log ""
}