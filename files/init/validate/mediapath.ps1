#Validate mediaPath
If ((Test-Path $cfg.mediaPath) -eq $True) {
    $mPath = Get-Item -Path $cfg.mediaPath
}
Else {
    Log "`nPath not found: $($cfg.mediaPath)"
    Log "Ensure the path specified for 'mediaPath' in $($prop.cfg_path) exists and is accessible."
    Log "Aborting script."
    DeleteLockFile
    Exit
}