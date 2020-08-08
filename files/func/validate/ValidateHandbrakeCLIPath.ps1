#Validate HandbrakeCLI path
Function ValidateHandbrakeCLIPath {

    param(
        [String]$Path
    )

    $bin = 'handbrake-cli'

    If ($isWindows) {
        $bin = 'HandBrakeCLI.exe'
    }

    $handbrake = Join-Path $Path $bin

    If (-Not (Test-Path $handbrake)) {
        Log "`n$($bin) could not be found at $($Path)."
        Log "Ensure the path specified for 'handbrakecli_bin_dir' in $($prop.cfg_path) is correct."
        Log "Aborting script."
        DeleteLockFile
        Exit
    }
}