# Populate file list
$fileCount=0
$mPath = Get-Item -Path $cfg.mediaPath
$ignoreList = Get-Content $prop.ignore_path
$fileList = Get-ChildItem "$($mPath.FullName)" -Include ( $cfg.fileTypes -split ',' ).trim() -Exclude $ignoreList -recurse | ForEach-Object { $fileCount++; If ($fileCount -eq 1) { Write-Output -NoNewLine "`rFound $fileCount file so far..." } Else { Write-Output -NoNewLine "`rFound $fileCount files so far..." -foregroundcolor green};$_}

ListFiles