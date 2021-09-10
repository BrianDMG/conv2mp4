#Print any encoding failures that occurred
Function Write-Failures {

  If ($failedEncodes.Count -ge 1) {
    Add-Log "`nThe following $($failedEncodes.Count) encoding failure(s) occurred:"

    ForEach ($file in $failedEncodes) {
      Add-Log "`t$($corruptFiles.indexOf($file)+1). $file"
    }

    Add-Log ''
  }
  If ($corruptFiles.Count -ge 1) {
    Add-Log "`nFound the following $($corruptFiles.Count) corrupt file(s):"

    ForEach ($file in $corruptFiles) {
      Add-Log "`t$($corruptFiles.indexOf($file)+1). $file"
    }

    Add-Log ''
  }

}