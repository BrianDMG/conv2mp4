# Delete garbage files
Function CollectGarbage {

    $garbageList = Get-ChildItem "$((Get-Item -Path $cfg.media_path).FullName)" -Include ( $cfg.garbage_include_file_types -split ',' ).trim() -Recurse

    If ($garbageList.Count -ge 1) {
        Log "`nGarbage Collection: The following $($garbageList.Count) file(s) were deleted:"
    }
    Else {
        Write-Output "Garbage Collection: No garbage found in $($cfg.media_path)."
    }

    ForEach ($turd in $garbageList) {
        Log "`t$($garbageList.indexOf($turd)+1). $turd"
        Try {
            Remove-Item $turd -Force -ErrorAction Stop
        }
        Catch {
            Log "$($time.Invoke()) ERROR: $turd could not be deleted. Full error below."
            Log $_
        }
    }
}