Write-Output 'Running preflight checks...'

#Import functions
Get-ChildItem -Path $prop.paths.functions.func_basepath -Include "*.ps1" -Recurse |
  ForEach-Object {
    . $_
  }

#Validate and create or wait on lock file
Confirm-LockFilePath -Path $prop.paths.files.lock

#Generate log file
New-Log -LogPath $prop.paths.files.log -DateFormat $prop.formatting.date

#Validate log path
Confirm-LogPath -Path  $prop.paths.files.log

#Validate ignore path
Confirm-IgnorePath -Path $prop.paths.files.ignore

#Validate usage statistics exists
Confirm-UsageStatisticsPath -Path $prop.paths.files.stats

#Validate ffmpeg.exe path
If ([Environment]::GetEnvironmentVariable('FFMPEG_BIN_DIR')) {
  $cfg.paths.ffmpeg_bin_dir = $([Environment]::GetEnvironmentVariable('FFMPEG_BIN_DIR'))
}
Confirm-FFMPEGPath -Path $cfg.paths.ffmpeg_bin_dir

#Validate HandbrakeCLI path
If ([Environment]::GetEnvironmentVariable('HANDBRAKECLI_BIN_DIR')) {
  $cfg.paths.handbrakecli_bin_dir = $([Environment]::GetEnvironmentVariable('HANDBRAKECLI_BIN_DIR'))
}
Confirm-HandbrakeCLIPath -Path $cfg.paths.handbrakecli_bin_dir

#Validate media_path
If ([Environment]::GetEnvironmentVariable('MEDIA_PATH')) {
  $cfg.paths.media_path = $([Environment]::GetEnvironmentVariable('MEDIA_PATH'))
}
Confirm-MediaPath -Path $cfg.paths.media_path

#Validate OutPath
If ($cfg.paths.use_out_path -eq 'true') {
  If ([Environment]::GetEnvironmentVariable('OUTPATH')) {
    $cfg.paths.out_path = $([Environment]::GetEnvironmentVariable('OUTPATH'))
  }
  Confirm-OutPath -Path $cfg.paths.out_path
}

#Validate config booleans
#TODO: REWORK for non-flat path
#Confirm-ConfigBooleans

#Rotate logs
If ($cfg.logging.rotate -gt 0) {
  Remove-ExpiredLogs -LogPath $prop.paths.files.logDir  -ExpiredLogInterval $cfg.logging.rotate
}