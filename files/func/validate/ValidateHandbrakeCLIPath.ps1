#Validate HandbrakeCLI path
Function ValidateHandbrakeCLIPath {

    param(
        [String]$Path
    )

    If ($isWindows) {
        $handbrake = Join-Path $Path "HandBrakeCLI.exe"
    }
    Else {
        $handbrake = Join-Path $Path "handbrake-cli"
    }

    If (-Not (Test-Path $handbrake)) {
        Log "`nhandbrakecli.exe could not be found at $Path."
        Log "Ensure the path specified for 'handbrakecli_bin_dir' in $($prop.cfg_path) is correct."
        Log "Aborting script."
        #DeleteLockFile
        #Exit
    }
}