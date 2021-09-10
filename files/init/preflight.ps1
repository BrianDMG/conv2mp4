Write-Output 'Running preflight checks...'

#Import functions
Get-ChildItem -Path $prop.paths.functions.func_basepath -Include "*.ps1" -Recurse |
  ForEach-Object {
    . $_
  }

#Validate and create or wait on lock file
ValidateLockFilePath -Path $prop.paths.files.lock

#Generate log file
GenerateLog -LogPath $prop.paths.files.log -DateFormat $prop.formatting.date

#Validate log path
ValidateLogPath -Path  $prop.paths.files.log

#Validate ignore path
ValidateIgnorePath -Path $prop.paths.files.ignore

#Validate ffmpeg.exe path
If ([Environment]::GetEnvironmentVariable('FFMPEG_BIN_DIR')) {
  $cfg.paths.ffmpeg_bin_dir = $([Environment]::GetEnvironmentVariable('FFMPEG_BIN_DIR'))
}
ValidateFFMPEGPath -Path $cfg.paths.ffmpeg_bin_dir

#Validate HandbrakeCLI path
If ([Environment]::GetEnvironmentVariable('HANDBRAKECLI_BIN_DIR')) {
  $cfg.paths.handbrakecli_bin_dir = $([Environment]::GetEnvironmentVariable('HANDBRAKECLI_BIN_DIR'))
}
ValidateHandbrakeCLIPath -Path $cfg.paths.handbrakecli_bin_dir

#Validate media_path
If ([Environment]::GetEnvironmentVariable('MEDIA_PATH')) {
  $cfg.paths.media_path = $([Environment]::GetEnvironmentVariable('MEDIA_PATH'))
}
ValidateMediaPath -Path $cfg.paths.media_path

#Validate OutPath
If ($cfg.paths.use_out_path -eq 'true') {
  If ([Environment]::GetEnvironmentVariable('OUTPATH')) {
    $cfg.paths.out_path = $([Environment]::GetEnvironmentVariable('OUTPATH'))
  }
  ValidateOutPath -Path $cfg.paths.out_path
}

#Validate config booleans
#TODO: REWORK for non-flat path
#ValidateConfigBooleans

#Rotate logs
If ($cfg.logging.rotate -gt 0) {
  RotateLog -LogPath $prop.paths.files.logDir  -RotateLogInterval $cfg.logging.rotate
}