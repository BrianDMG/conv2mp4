<#======================================================================================================================
conv2mp4-ps v5.0.0 - https://github.com/BrianDMG/conv2mp4-ps

This Powershell script will recursively search through a user-defined file path and convert all videos of user-specified
include_file_types to MP4 with H264 video and AAC audio using ffmpeg. If a conversion failure is detected, the script re-encodes
the file with HandbrakeCLI. Upon successful encoding, Plex libraries are (optionally) refreshed and source file is deleted.
The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server.
========================================================================================================================#>

Set-Location -Path $PSScriptRoot

#Test if $IsWindows variable exists, if not assumes platform is Windows (backwards compatibility)
If(-not (Test-Path Variable:IsWindows))
{
    $IsWindows = $true
    $IsLinux = $IsMacOS = $false
}

#Load properties file
$propFile = Convert-Path "files\prop\properties"
$propRawString = Get-Content "$propFile" | Out-String
$propStringToConvert = $propRawString -replace '\\', '\\'
$prop = ConvertFrom-StringData $propStringToConvert
Remove-Variable -Name propFile, propRawString, propSTringToConvert

#Load configuration
$cfgRawString = Get-Content "$($prop.cfg_path)" | Out-String
$cfgStringToConvert = $cfgRawString -replace '\\', '\\'
$cfg = ConvertFrom-StringData $cfgStringToConvert
Remove-Variable -Name cfgRawString, cfgStringToConvert

# Time and format used for timestamps in the log
$time = {Get-Date -format "MM/dd/yy HH:mm:ss"}

# Get current time to store as start time for script
$startScriptTime = (Get-Date)

# Initialize 'video length converted' to 0
$cumulativeVideoDuration = [timespan]::fromseconds(0)

#Execute preflight checks
$preflightPath = Convert-Path "$($prop.preflight)"
. $preflightPath

#Build processing queue and list its contents
$buildQueuePath = Convert-Path "$($prop.buildqueue)"
. $buildQueuePath

# Begin performing operations of files
ForEach ($file in $fileList) {

    $title = $file.BaseName

    $sourceFile = Convert-Path "$($file.DirectoryName)\$($file.BaseName)$($file.Extension)"

    $fileSubDirs = ($file.DirectoryName).Substring($cfg.media_path.Length, ($file.DirectoryName).Length - $cfg.media_path.Length)

  }