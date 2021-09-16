# Validate or create log path
Function Confirm-UsageStatisticsPath {

  Param (
    [String]$Path
  )

  $statsTemplatePath = Join-Path $prop.paths.files.templates $prop.templates.stats

  If (-Not (Test-Path $Path)) {
    Try {
      Write-Output "Usage stastics not found at $Path - creating..."
      Copy-Item -Path $statsTemplatePath -Destination $Path -Force
    }
    Catch {
      Add-Log "Could not create $Path. Aborting script."
      Remove-LockFile
      Exit
    }
  }

}