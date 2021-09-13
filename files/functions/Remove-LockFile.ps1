#Delete lock file
Function Remove-LockFile {
    Try {
        Remove-Item $prop.paths.files.lock -Force -ErrorAction Stop
    }
    Catch {
        Add-Log "$($time.Invoke()) ERROR: $($prop.paths.files.lock) could not be deleted. Full error below."
        Add-Log $_
    }
}