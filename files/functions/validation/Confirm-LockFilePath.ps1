Function Confirm-LockFilePath {

  Param (
    [String]$Path,
    [String]$DateFormat
  )

  #Date format
  $date = Get-Date -format $DateFormat

  # Create lock file (for the purpose of ensuring only one instance of this script is running)
  If (-Not (Test-Path $Path)) {
    New-Item $Path -Force
    Add-Content -Path $Path -Value $date
  }
  Else {
    Write-Output "Script is already running in another instance. Waiting..."

    Do {
      Test-Path $Path > $null
      Start-Sleep 10
    }
    Until (-Not (Test-Path $Path))

    Write-Output "Other instance ended. Continuing..."
    New-Item $Path -Force
  }

  #Clear-Host

}