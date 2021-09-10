#Validate HandbrakeCLI path
Function Confirm-HandbrakeCLIPath {

  Param (
    [String]$Path
  )

  $bin = 'HandBrakeCLI'

  If ($isWindows) {
    $bin = "$($bin).exe"
  }

  $handbrake = Join-Path $Path $bin

  If (-Not (Test-Path $handbrake)) {
    Add-Log "`n$($bin) could not be found at $($Path)."
    Add-Log "Ensure the path specified for 'handbrakecli_bin_dir' in $($prop.paths.files.cfg_path) is correct."
    Add-Log "Aborting script."
    Remove-LockFile
    Exit
  }

}