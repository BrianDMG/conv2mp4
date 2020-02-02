# Print initial wait notice to console
Write-Output "`nBuilding file list, please wait. This may take a while, especially for large libraries.`n"

# Populate file list
If ($cfg.use_ignore_list) {
    $cfg.include_file_types += ", *.mp4"
    $fileList = Get-ChildItem "$((Get-Item -Path $cfg.media_path).FullName)" -Include ( $cfg.include_file_types -split ',' ).trim() -Exclude $(Get-Content $prop.ignore_path) -Recurse |
    ForEach-Object {
        Write-Progress "`rFound $(@($fileList).indexOf($file)+1) file(s) so far..."
        $_
    }
}
Else {
    $fileList = Get-ChildItem "$((Get-Item -Path $cfg.media_path).FullName)" -Include ( $cfg.include_file_types -split ',' ).trim() -Recurse |
    ForEach-Object {
        Write-Progress "`rFound $(@($fileList).indexOf($file)+1) file(s) so far..."
        $_
    }
}

PrintFileQueue