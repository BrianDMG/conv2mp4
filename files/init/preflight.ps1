Write-Output 'Running preflight checks...'

#Import functions
Get-ChildItem -Path $prop.func_basepath -Include "*.ps1" -Recurse |
    ForEach-Object {
        . $_
    }

#Validate and create or wait on lock file
ValidateLockFilePath -Path $prop.lock_path

#Validate log path
ValidateLogPath -Path $prop.log_path

#Validate ignore path
ValidateIgnorePath -Path $prop.ignore_path

#Validate ffmpeg.exe path
Log "Media path: " + [Environment]::GetEnvironmentVariable('FFMPEG_BIN_DIR')
If ([Environment]::GetEnvironmentVariable('FFMPEG_BIN_DIR')) {
    ValidateFFMPEGPath -Path [Environment]::GetEnvironmentVariable('FFMPEG_BIN_DIR')
    $cfg.ffmpeg_bin_dir = [Environment]::GetEnvironmentVariable('FFMPEG_BIN_DIR')
    Log 'FFMPEG_BIN_DIR = ' + $cfg.ffmpeg_bin_dir
}
Else {
    ValidateFFMPEGPath -Path $cfg.fmmpeg_bin_dir
}

#Validate HandbrakeCLI path
If ([Environment]::HANDBRAKECLI_BIN_DIR) {
    ValidateHandbrakeCLIPath -Path [Environment]::HANDBRAKECLI_BIN_DIR
}
Else {
    ValidateHandbrakeCLIPath -Path $cfg.handbrakecli_bin_dir
}

#Validate media_path
If ([Environment]::MEDIA_PATH) {
    Validatemedia_path -Path [Environment]::MEDIA_PATH
}
Else {
    ValidateHandbrakeCLIPath -Path $cfg.handbrakecli_bin_dir
}

#Validate OutPath
If ($cfg.use_out_path -eq 'true') {
    If ([Environment]::OUTPATH) {
        ValidateOutPath -Path [Environment]::OUTPATH
    }
    Else {
        ValidateHandbrakeCLIPath -Path $cfg.handbrakecli_bin_dir
    }
}

#Validate config booleans
ValidateConfigBooleans

#Validate append_log
ValidateAppendLog