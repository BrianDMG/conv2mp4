# List files in the queue in the log
Function Write-FileQueue {

  If ($fileList.Count -ge 1) {
    Add-Log "`nThere are $($fileList.Count) file(s) in the queue:`n"
  }
  Else {
    Write-Output "`nThere are no files to be converted in $($cfg.media_path)."
  }

  ForEach ($file in $fileList) {
    Add-Log "$(@($fileList).indexOf($file)+1). $file"
  }

  Add-Log ""

}