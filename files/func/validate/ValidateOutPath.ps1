Function ValidateOutPath {

    param(
        [String]$Path
    )

    If (-Not (Test-Path $Path)) {
        Try {
            mkdir $Path -Force
        }
        Catch {
            Log "Could not create $Path. Aborting script."
            DeleteLockFile
            Exit
        }
    }
}