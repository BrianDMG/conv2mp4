# List files in the queue in the log
Function PrintFileQueue {

    If ($fileList.Count -ge 1) {
        Log "`nThere are $($fileList.Count) file(s) in the queue:`n"
    }
    Else {
        Write-Output "`nThere are no files to be converted in $($cfg.media_path)."
    }

    ForEach ($file in $fileList) {
        Log "$(@($fileList).indexOf($file)+1). $file"
    }
    Log ""
}