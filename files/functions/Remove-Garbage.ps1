# Delete garbage files
Function Remove-Garbage {

  $garbageList = Get-ChildItem "$((Get-Item -Path $cfg.paths.media_path).FullName)" -Include ( $cfg.cleanup.include_file_types -split ',' ).trim() -Recurse

  If ($garbageList.Count -ge 1) {
    Add-Log "`nGarbage Collection: The following $($garbageList.Count) file(s) were deleted:"
  }
  Else {
    Write-Output "Garbage Collection: No garbage found in $($cfg.paths.media_path)."
  }

  ForEach ($turd in $garbageList) {
    Add-Log "`t$($garbageList.indexOf($turd)+1). $turd"

    Try {
      Remove-Item $turd -Force -ErrorAction Stop
    }
    Catch {
      Add-Log "$($time.Invoke()) ERROR: $turd could not be deleted. Full error below."
      Add-Log $_
    }
  }

}