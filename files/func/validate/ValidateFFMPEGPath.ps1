#Validate ffmpeg.exe path
Function ValidateFFMPEGPath {
    param(
        [String]$Path
    )

    If ($isWindows) {
        $ffmpeg = Join-Path $Path "ffmpeg.exe"
    }
    Else {
        $ffmpeg = Join-Path $Path "ffmpeg"
    }

    If (-Not (Test-Path $ffmpeg)) {
        Log "`nffmpeg.exe could not be found at $Path."
        Log "Ensure the path specified for 'fmmpeg_bin_dir' in $($prop.cfg_path) is correct."
        Log "Aborting script."
        DeleteLockFile
        Exit
    }
    Else {
        If ($Path -eq [Environment]::FFMPEG_BIN_DIR) {
            $cfg.ffmpeg_bin_dir = [Environment]::FFMPEG_BIN_DIR
        }
    }

    If ($isWindows) {
        $ffprobe = Join-Path $Path "ffprobe.exe"
    }
    Else {
        $ffprobe = Join-Path $Path "ffprobe"
    }

    If (-Not (Test-Path $ffprobe)) {
        Log "`nffprobe.exe could not be found at $Path."
        Log "Ensure the path specified for 'fmmpeg_bin_dir' in $($prop.cfg_path) is correct."
        Log "Aborting script."
        DeleteLockFile
        Exit
    }

}