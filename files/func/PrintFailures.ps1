#Print any encoding failures that occurred
Function PrintFailures {
    If ($failedEncodes.Count -ge 1) {
        Log "`nThe following encoding failure(s) occurred:"
        ForEach ($file in $failedEncodes) {
            Log $file
        }
    }
    If ($corruptFiles.Count -ge 1) {
        Log "`nFound the following corrupt file(s):"
        ForEach ($file in $corruptFiles) {
            Log $file
        }
    }
}