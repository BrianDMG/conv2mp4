# Validate or create ignore path
Function Confirm-IgnorePath {

  Param (
    [String]$Path
  )

  If (-Not (Test-Path $Path)) {
    Write-Output "Didn't find ignore list at $Path - creating..."
    New-Item $Path -Force
  }

}