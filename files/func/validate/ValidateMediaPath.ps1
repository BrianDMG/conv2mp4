#Validate mediaPath
Function ValidateMediaPath {

    param(
        [String]$Path
    )

    If (-Not (Test-Path $Path)) {
        Log "`nPath not found: $Path"
        Log "Ensure the path specified for 'mediaPath' in $($prop.cfg_path) exists and is accessible."
        Log "Aborting script."
        DeleteLockFile
        Exit
    }
}