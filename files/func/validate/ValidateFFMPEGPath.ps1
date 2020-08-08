#Validate ffmpeg.exe path
Function ValidateFFMPEGPath {
    param(
        [String]$Path
    )

    $bin = 'ffmpeg'

    If ($isWindows) {
        $bin = $bin + '.exe'
    }

    $ffmpeg = Join-Path $Path $bin

    If (-Not (Test-Path $ffmpeg)) {
        Log "`n$($bin) could not be found in $($Path)."
        Log "Ensure the path specified for 'fmmpeg_bin_dir' in $($prop.cfg_path) is correct."
        Log "Aborting script."
        DeleteLockFile
        Exit
    }

    $bin = 'ffprobe'

    If ($isWindows) {
        $bin = $bin + '.exe'
    }

    $ffprobe = Join-Path $Path $bin

    If (-Not (Test-Path $ffprobe)) {
        Log "`n$($bin) could not be found in $($Path)."
        Log "Ensure the path specified for 'fmmpeg_bin_dir' in $($prop.cfg_path) is correct."
        Log "Aborting script."
        DeleteLockFile
        Exit
    }

}