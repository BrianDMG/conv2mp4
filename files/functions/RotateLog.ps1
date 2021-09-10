Function RotateLog {
  Param (
    [string]$RotateLogInterval,
    [String]$LogPath
  )

  #Rotate logs
  Get-ChildItem $LogPath -Recurse -Force -ea 0 |
    ? {!$_.PsIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-$($RotateLogInterval))} |

    ForEach-Object {
      Log "Log rotation: deleting $($_.FullName)"
      Remove-Item $_ -Force
    }

}