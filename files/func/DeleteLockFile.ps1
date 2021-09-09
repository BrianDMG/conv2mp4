#Delete lock file
Function DeleteLockFile {
    Try {
        Remove-Item $prop.paths.files.lock -Force -ErrorAction Stop
    }
    Catch {
        Log "$($time.Invoke()) ERROR: $($prop.paths.files.lock) could not be deleted. Full error below."
        Log $_
    }
}