#Print any encoding failures that occurred
Function PrintFailures {
    If ($failedEncodes.Count -ge 1) {
        Log "`nThe following $($failedEncodes.Count) encoding failure(s) occurred:"
        ForEach ($file in $failedEncodes) {
            Log "`t$($corruptFiles.indexOf($file)+1). $file"
        }
        Log ''
    }
    If ($corruptFiles.Count -ge 1) {
        Log "`nFound the following $($corruptFiles.Count) corrupt file(s):"
        ForEach ($file in $corruptFiles) {
            Log "`t$($corruptFiles.indexOf($file)+1). $file"
        }
        Log ''
    }
}