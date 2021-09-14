#Validate media
Function Confirm-MediaPath {

  Param (
    [String]$Path
  )

  If (-Not (Test-Path $Path)) {
    Add-Log "`nPath not found: $Path"
    Add-Log "Ensure the path specified for '$cf.paths.media' in $($prop.paths.files.cfg) exists and is accessible."
    Add-Log "Aborting script."
    Remove-LockFile
    Exit
  }

}