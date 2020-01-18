#Validate ffmpeg.exe path 
$ffmpeg = Join-Path $cfg.ffmpegBinDir "ffmpeg.exe"

If (-Not (Test-Path $ffmpeg)) {
    Log "`nffmpeg.exe could not be found at $($cfg.ffmpegBinDir)."
    Log "Ensure the path specified for 'ffmpegBinDir' in $($prop.cfg_path) is correct."
    Log "Aborting script."
    DeleteLockFile
    Exit
}