#Validate ffmpeg path
Function Confirm-FFMPEGPath {

  Param (
    [String]$Path
  )

  $bin = 'ffmpeg'

  If ($IsWindows) {
    $bin = "$($bin).exe"
  }

  $ffmpeg = Join-Path $Path $bin

  If (-Not (Test-Path $ffmpeg)) {
    Add-Log "`n$($bin) could not be found in $($Path)."
    Add-Log "Ensure the path specified for 'fmmpeg_bin_dir' in $($prop.paths.files.cfg) is correct."
    Add-Log "Aborting script."
    Remove-LockFile
    Exit
  }

  $bin = 'ffprobe'

  If ($IsWindows) {
    $bin = $bin + '.exe'
  }

  $ffprobe = Join-Path $Path $bin

  If (-Not (Test-Path $ffprobe)) {
    Add-Log "`n$($bin) could not be found in $($Path)."
    Add-Log "Ensure the path specified for 'fmmpeg_bin_dir' in $($prop.paths.files.cfg) is correct."
    Add-Log "Aborting script."
    Remove-LockFile
    Exit
  }

}