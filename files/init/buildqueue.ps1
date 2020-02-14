# Print initial wait notice to console
Write-Output "`nBuilding file list, please wait. This may take a while, especially for large libraries.`n"

# Populate file list
If ($cfg.use_ignore_list) {
    $cfg.include_file_types += ", *.mp4"
    $fileList = Get-ChildItem "$((Get-Item -Path $cfg.media_path).FullName)" -Include ( $cfg.include_file_types -split ',' ).trim() -Exclude $(Get-Content $prop.ignore_path) -Recurse |
        ForEach-Object {$counter = 1} {
            Write-Progress -Activity "Found $($counter) file(s) so far..." -Status "Processing..." -CurrentOperation "$($_.FullName)"
            $counter++
        }
}
Else {
    $fileList = Get-ChildItem "$((Get-Item -Path $cfg.media_path).FullName)" -Include ( $cfg.include_file_types -split ',' ).trim() -Recurse |
        ForEach-Object {$counter = 1} {
            Write-Progress -Activity "Found $($counter) file(s) so far..." -Status "Processing..." -CurrentOperation "$($_.FullName)"
            $counter++
        }
}

PrintFileQueue