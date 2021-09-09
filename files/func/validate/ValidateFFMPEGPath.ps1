#Validate ffmpeg.exe path
Function ValidateFFMPEGPath {
    param(
        [String]$Path
    )

    $bin = 'ffmpeg'

    If ($IsWindows) {
        $bin = "$($bin).exe"
    }

    $ffmpeg = Join-Path $Path $bin

    If (-Not (Test-Path $ffmpeg)) {
        Log "`n$($bin) could not be found in $($Path)."
        Log "Ensure the path specified for 'fmmpeg_bin_dir' in $($prop.paths.files.cfg) is correct."
        Log "Aborting script."
        DeleteLockFile
        Exit
    }

    $bin = 'ffprobe'

    If ($IsWindows) {
        $bin = $bin + '.exe'
    }

    $ffprobe = Join-Path $Path $bin

    If (-Not (Test-Path $ffprobe)) {
        Log "`n$($bin) could not be found in $($Path)."
        Log "Ensure the path specified for 'fmmpeg_bin_dir' in $($prop.paths.files.cfg) is correct."
        Log "Aborting script."
        DeleteLockFile
        Exit
    }

}