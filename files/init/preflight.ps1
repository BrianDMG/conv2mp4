Write-Output 'Running preflight checks...'

#Validate and create or wait on lock file
. $prop.validate_lockfile

#Validate log path
. $prop.validate_logpath

#Validate ignore path
. $prop.validate_ignorepath

#Validate ffmpeg.exe path 
. $prop.validate_ffmpegpath

#Validate ffprobe.exe path
. $prop.validate_ffprobepath

#Validate HandbrakeCLI path
. $prop.validate_handbrakecli

#Validate mediaPath
. $prop.validate_mediapath