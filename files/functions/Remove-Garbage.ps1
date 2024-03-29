# Delete garbage files
Function Remove-Garbage {

  $garbageList = Get-ChildItem "$((Get-Item -Path $cfg.paths.media).FullName)" -Include ( $cfg.cleanup.include_file_types -split ',' ).trim() -Recurse

  If ($garbageList.Count -ge 1) {
    Add-Log "`nGarbage Collection: Deleted the following $($garbageList.Count) file(s):"
  }
  Else {
    Write-Output "Garbage Collection: No garbage found in $($cfg.paths.media)."
  }

  ForEach ($turd in $garbageList) {

    If ($garbageList.Count -gt 1) {
      Add-Log "`t$($garbageList.indexOf($turd)+1). $turd"
    }
    Else {
      Add-Log "`t1. $turd"
    }

    Try {
      Remove-Item $turd -Force -ErrorAction Stop
    }
    Catch {
      Add-Log "$($time.Invoke()) ERROR: $turd could not be deleted. Full error below."
      Add-Log $_
    }
  }

}