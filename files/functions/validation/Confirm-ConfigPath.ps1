#Load config file
Function Confirm-ConfigPath {

  Param (
    [String]$Path
  )

  If (-Not (Test-Path $Path)) {
    Write-Output "Cannot find $Path."
    Start-Sleep 10
    Exit
  }
  Else {
    # Create a backup of the cfg file
    Copy-Item $Path "$($Path).bk"
    Write-Output "`nCreated a backup of $Path"
  }

}