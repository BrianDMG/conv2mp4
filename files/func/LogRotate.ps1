Function LogRotate {
  Param (
    [string]$LogRotatePeriod,
    [String]$LogPath
  )

  #Rotate logs
  Get-ChildItem $logPath -Recurse -Force -ea 0 |
  ? {!$_.PsIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-$($logRotatePeriod))} |

  ForEach-Object {
    Write-Output "Log rotation: deleting $($_.FullName)"
    $_ | Remove-Item -Force
  }

}