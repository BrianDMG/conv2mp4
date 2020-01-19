#Validate ffprobe.exe path
$ffprobe = Join-Path $cfg.ffmpegBinDir "ffprobe.exe"
$testFFPPath = Test-Path $ffprobe

If ($testFFPPath -eq $False) {
    Log "`nffprobe.exe could not be found at $($cfg.ffmpegBinDir)."
    Log "Ensure the path specified for 'ffmpegBinDir' in $($prop.cfg_path) is correct."
    Log "Aborting script."
    DeleteLockFile
    Exit
}