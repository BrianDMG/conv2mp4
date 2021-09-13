Function Confirm-OutPath {

  Param (
    [String]$Path
  )

  If (-Not (Test-Path $Path)) {
    Try {
      New-Item -Path $Path -Force
    }
    Catch {
      Add-Log "Could not create $Path. Aborting script."
      Remove-LockFile
      Exit
    }
  }

}