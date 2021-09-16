Function Remove-ExpiredLogs {

  Param (
    [String]$ExpiredLogInterval,
    [String]$LogPath
  )

  #Rotate logs
  Get-ChildItem $LogPath -Recurse -Force -ea 0 |
    Where-Object {!$_.PsIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-$($ExpiredLogInterval))} |

    ForEach-Object {
      Add-Log "Log rotation: deleting $($_.FullName)"
      Remove-Item $_ -Force
    }

}