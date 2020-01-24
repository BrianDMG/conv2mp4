#Validate ffmpeg.exe path
Function ValidateFFMPEGPath {
    param(
        [String]$Path
    )

    $ffmpeg = Join-Path $Path "ffmpeg.exe"

    If (-Not (Test-Path $ffmpeg)) {
        Log "`nffmpeg.exe could not be found at $Path."
        Log "Ensure the path specified for 'ffmpegBinDir' in $($prop.cfg_path) is correct."
        Log "Aborting script."
        DeleteLockFile
        Exit
    }

    $ffprobe = Join-Path $Path "ffprobe.exe"

    If (-Not (Test-Path $ffprobe)) {
        Log "`nffprobe.exe could not be found at $Path."
        Log "Ensure the path specified for 'ffmpegBinDir' in $($prop.cfg_path) is correct."
        Log "Aborting script."
        DeleteLockFile
        Exit
    }

}