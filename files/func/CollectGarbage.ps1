# Delete garbage files
Function CollectGarbage {

    $garbageList = Get-ChildItem "$($mPath.FullName)\*" -i ( $cfg.garbage_include_file_types -split ',' ).trim() -Recurse
    $garbageNum = 0

    ForEach ($turd in $garbageList) {
            $garbageNum++
    }

    If ($garbageNum -eq 1) {
        Log "`nGarbage Collection: The following file was deleted:"
    }
    Elseif ($garbageNum -gt 1) {
        Log "`nGarbage Collection: The following $garbageNum files were deleted:"
    }
    Else {
        Log ("`nGarbage Collection: No garbage found in $($cfg.media_path).")
    }
    Log ""

    $garbageNum = 0

    ForEach ($turd in $garbageList) {
        $garbageNum++
        Log "$($garbageNum). $turd"
        Try {
            Remove-Item $turd -Force -ErrorAction Stop
        }
        Catch {
            Log "$($time.Invoke()) ERROR: $turd could not be deleted. Full error below."
            Log $_
        }
    }
}