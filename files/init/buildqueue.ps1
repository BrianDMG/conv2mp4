# Print initial wait notice to console
Write-Output "`nBuilding file list, please wait. This may take a while, especially for large libraries.`n"

# Populate file list
$fileCount=0
$mPath = Get-Item -Path $cfg.media_path
$ignoreList = Get-Content $prop.ignore_path
$fileList = Get-ChildItem "$($mPath.FullName)" -Include ( $cfg.include_file_types -split ',' ).trim() -Exclude $ignoreList -Recurse |
    ForEach-Object {
        $fileCount++
        Write-Progress "`rFound $fileCount file(s) so far..."
        $_
    }

PrintFileQueue