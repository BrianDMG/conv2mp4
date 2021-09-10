# Validate or create log path
Function Confirm-UsageStatisticsPath {

  Param (
    [String]$Path
  )

  If (-Not (Test-Path $Path)) {
    Try {
      Write-Output "Usage stastics not found at $Path - creating..."
      Copy-Item -Path $prop.paths.files.stats_template -Destination $Path -Force
    }
    Catch {
      Add-Log "Could not create $Path. Aborting script."
      Remove-LockFile
      Exit
    }
  }

}