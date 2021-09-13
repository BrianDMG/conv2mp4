#Delete lock file
Function DeleteLockFile {
    Try {
        Remove-Item $prop.lock_path -Force -ErrorAction Stop
    }
    Catch {
        Log "$($time.Invoke()) ERROR: $($prop.lock_path) could not be deleted. Full error below."
        Log $_
    }
}