#Validate HandbrakeCLI path
$handbrake = Join-Path $cfg.handbrakeDir "HandBrakeCLI.exe"
$testHBPath = Test-Path $handbrake

If ($testHBPath -eq $False) {
    Log "`nhandbrakecli.exe could not be found at $($cfg.handbrakeDir)."
    Log "Ensure the path specified for 'handbrakeDir' in $($prop.cfg_path) is correct."
    Log "Aborting script."
    DeleteLockFile
    Exit
}