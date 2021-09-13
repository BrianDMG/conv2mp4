# Validate or create log path
Function Confirm-LogPath {

  Param (
    [String]$Path
  )

  If (-Not (Test-Path $Path)) {
    Try {
      Write-Output "Log not found at $Path - creating..."
      New-Item $Path -Force
    }
    Catch {
      Add-Log "Could not create $Path. Aborting script."
      Remove-LockFile
      Exit
    }
  }

}