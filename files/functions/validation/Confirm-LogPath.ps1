# Validate or create log path
Function Confirm-LogPath {

  Param (
    [String]$Path
  )

  If (-Not (Test-Path $Path)) {
    Try {
      Write-Output "Add-Log not found at $Path - creating..."
      New-Item $Path -Force
    }
    Catch {
      #TODO Finish catch condition
    }
  }

}