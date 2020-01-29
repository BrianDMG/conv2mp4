#Print any encoding failures that occurred
Function PrintFailures {
    If ($failedEncodes -ge 1) {
        Log "`nThe following encoding failure(s) occurred:"
        ForEach ($file in $failedEncodes) {
            Log $file
        }
    }
    If ($corruptFiles -ge 1) {
        Log "`nFound the following corrupt file(s):"
        ForEach ($file in $corruptFiles) {
            Log $file
        }
    }
}