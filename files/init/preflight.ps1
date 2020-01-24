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
ValidateFFMPEGPath -Path $cfg.ffmpegBinDir

#Validate HandbrakeCLI path
ValidateHandbrakeCLIPath -Path $cfg.handbrakeDir

#Validate mediaPath
ValidateMediaPath -Path $cfg.mediaPath

#Validate config booleans
ValidateConfigBooleans