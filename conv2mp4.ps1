<#======================================================================================================================
conv2mp4-docker v5.0.0 - https://gitlab.com/BrianDMG/conv2mp4-docker

This Powershell script will recursively search through a user-defined file path and convert all videos of user-specified
include_file_types to MP4 with H264 video and AAC audio using ffmpeg. If a conversion failure is detected, the script re-encodes
the file with HandbrakeCLI. Upon successful encoding, Plex libraries are (optionally) refreshed and source file is deleted.
The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server.
========================================================================================================================#>

Set-Location -Path $PSScriptRoot

#Load properties file
$propFile = Convert-Path "files\prop\properties.yaml"
$prop = Get-Content "$propFile" | ConvertFrom-Yaml
Remove-Variable -Name propFile

#Load configuration
$cfgFile = Convert-Path "$($prop.paths.files.cfg)"
$cfg = Get-Content "$cfgFile" | ConvertFrom-Yaml
Remove-Variable -Name cfgFile

# Time and format used for timestamps in the log
$time = {Get-Date -format "MM/dd/yy HH:mm:ss"}

# Get current time to store as start time for script
$startScriptTime = (Get-Date)

# Initialize 'video length converted' to 0
$cumulativeVideoDuration = [timespan]::fromseconds(0)

#Execute preflight checks
$preflightPath = Convert-Path "$($prop.paths.init.preflight)"
. $preflightPath

#Build processing queue and list its contents
$buildQueuePath = Convert-Path "$($prop.paths.init.buildqueue)"
. $buildQueuePath

# Begin performing operations of files
ForEach ($file in $fileList) {

  $title = $file.BaseName

  $sourceFile = Join-Path "$($file.DirectoryName)" "$($file.BaseName)$($file.Extension)"
  $sourceFile = Convert-Path "$($sourceFile)"

  $fileSubDirs = ($file.DirectoryName).Substring($cfg.paths.media.Length, ($file.DirectoryName).Length - $cfg.paths.media.Length)

  If ($cfg.paths.use_out_path) {
    $targetPath = Convert-Path "$($cfg.paths.out_path)$($fileSubDirs)\"

    If (-Not (Test-Path $targetPath)) {
      New-Item -Path $targetPath -Force
    }

    $targetFile = Convert-Path "$($targetPath)"
    $targetFile = Join-Path "$($targetFile)" "$($file.BaseName).mp4.conv2mp4"
  }
  Else {
    $targetFile = Convert-Path "$($file.DirectoryName)\"
    $targetFile = Join-Path "$($targetFile)" "$($file.BaseName).mp4.conv2mp4"
  }

  $progress = ($(@($fileList).indexOf($file)+1) / $fileList.Count) * 100
  $progress = [Math]::Round($progress,2)

  Write-Progress -Activity "$sourceFile" -PercentComplete $progress -CurrentOperation "$($progress)% Complete"

  Add-Log "$($prop.formatting.standard_divider)"
  Add-Log "$($time.Invoke()) Processing - $($sourceFile)"
  Add-Log "$($time.Invoke()) File $(@($fileList).indexOf($file)+1) of $($fileList.Count) - Total queue $($progress)%"

  #Set targetFile final name
  If ($cfg.paths.use_out_path) {
    $targetFileRenamed = Convert-Path "$($targetPath)\"
    $targetFileRenamed = Join-Path "$($targetFileRenamed)" "$($file.BaseName).mp4"
  }
  Else {
    $targetFileRenamed = Convert-Path "$($file.DirectoryName)"
    $targetFileRenamed = Join-Path "$($targetFileRenamed)" "$($file.BaseName).mp4"
  }
  <#Test if $targetFile (.mp4) already exists, if yes then delete $sourceFile (.mkv)
  This outputs a more specific log message acknowleding the file already existed.#>
  If ((Test-Path "$($targetFileRenamed)") -And $file.Extension -ne ".mp4") {
    Remove-Item "$($sourceFile)" -Force
    Add-Log "$($time.Invoke()) Already exists: $($targetFileRenamed)"
    Add-Log "$($time.Invoke()) Deleted: $($sourceFile)."
    $duplicatesDeleted += @($sourceFile)
  }
  Else {
    #Codec discovery to determine whether video, audio, or both needs to be encoded
    $getAudioCodec = Get-Codec -DiscoverType Audio
    $getVideoCodec = Get-Codec -DiscoverType Video
    $getVideoDuration = Get-Codec -DiscoverType Duration

    # Video is already H264, Audio is already AAC
    If (!$getAudioCodec -OR !$getVideoCodec) {
      $failureCause = 'corruptCodec'
      Write-EncodeFailure
      Continue
    }
    Elseif ($getVideoCodec -eq 'h264' -AND $getAudioCodec -eq 'aac') {
      If ($file.Extension -ne ".mp4") {
        Add-Log "$($time.Invoke()) Video: $($getVideoCodec.ToUpper()), Audio: $($getAudioCodec.ToUpper()). Performing simple container conversion to MP4."
        Convert-File -ConvertType Simple -KeepSubs:$cfg.subtitles.keep
        $simpleConversion += @($sourceFile)
        $skipFile = $False
      }
      Else {
        $getVideoDuration = "00:00:00"
        $fileCompliant += @($sourceFile)
        $skipFile = $True
      }
    }
    # Video is already H264, Audio is not AAC
    ElseIf ($getVideoCodec -eq 'h264' -AND $getAudioCodec -ne 'aac') {
      Add-Log "$($time.Invoke()) Video: $($getVideoCodec.ToUpper()), Audio: $($getAudioCodec.ToUpper()). Encoding audio to AAC"
      Convert-File -ConvertType Audio -KeepSubs:$cfg.subtitles.keep
      $audioConversion += @($sourceFile)
      $skipFile = $False
    }
    # Video is not H264, Audio is already AAC
    ElseIf ($getVideoCodec -ne 'h264' -AND $getAudioCodec -eq 'aac') {
      Add-Log "$($time.Invoke()) Video: $($getVideoCodec.ToUpper()), Audio: $($getAudioCodec.ToUpper()). Encoding video to H264."
      Convert-File -ConvertType Video -KeepSubs:$cfg.subtitles.keep
      $videoConversion += @($sourceFile)
      $skipFile = $False
    }
    # Video is not H264, Audio is not AAC
    ElseIf ($getVideoCodec -ne 'h264' -AND $getAudioCodec -ne 'aac') {
      Add-Log "$($time.Invoke()) Video: $($getVideoCodec.ToUpper()), Audio: $($getAudioCodec.ToUpper()). Encoding video to H264 and audio to AAC."
      Convert-File -ConvertType Both -KeepSubs:$cfg.subtitles.keep
      $bothConversion += @($sourceFile)
      $skipFile = $False
    }

    If ($cfg.audio.force_stereo_clone) {
      Copy-StereoStream
    }

    # Refresh Plex libraries
    If ($cfg.plex.enable -AND (-Not($skipFile))) {
      Update-Plex
    }

    #Begin file comparison between old file and new file to determine conversion success
    If (-Not ($skipFile)) {
      $sourceFileCompare = Get-Item "$($sourceFile)"
      $targetFileCompare = Get-Item "$($targetFile)"

      # If new file is the same size as old file, log status and delete old file
      If ($targetFileCompare.length -eq $sourceFileCompare.length) {
        Compare-IfSame
      }

      # If new file is larger than old file, log status and delete old file
      Elseif ($targetFileCompare.length -gt $sourceFileCompare.length) {
        Compare-IfLarger
      }
      # If new file is much smaller than old file (indicating a failed conversion), log status, delete new file, and re-encode with HandbrakeCLI
      Elseif ($targetFileCompare.length -lt ($sourceFileCompare.length * $cfg.conversion.failover_threshold)) {
        Write-EncodeError

        #Begin Handbrake encode (lossy)
        Convert-File -ConvertType Handbrake -KeepSubs:$cfg.subtitles.keep

        # Load files for comparison
        $sourceFileCompare = Get-Item "$($sourceFile)"
        $targetFileCompare = Get-Item "$($targetFile)"

        # If new file still exceeds failover threshold, leave original file in place and log failure
        If ($targetFileCompare.length -lt ($sourceFileCompare.length * $cfg.conversion.failover_threshold)) {
          $failureCause = 'encodeFailure'
          Write-EncodeFailure
        }

        # If new file is the same size as old file, log status and delete old file
        Elseif ($targetFileCompare.length -eq $sourceFileCompare.length) {
          Compare-IfSame
        }

        # If new file is larger than old file, log status and delete old file
        Elseif ($targetFileCompare.length -gt $sourceFileCompare.length) {
          Compare-IfLarger
        }

        # If new file is smaller than old file, log status and delete old file
        Elseif ($targetFileCompare.length -lt $sourceFileCompare.length) {
          Compare-IfSmaller
        }
      }

      # If new file is smaller than old file, log status and delete old file
      Elseif ($targetFileCompare.length -lt $sourceFileCompare.length) {
        Compare-IfSmaller
      }

      #If $sourceFile was an mp4, rename $targetFile to remove "-NEW"
      $targetFileRenamed = "$($targetFile)" -replace ".conv2mp4",""
      Move-Item "$($targetFile)" "$($targetFileRenamed)"

      #If using out_path, delete empty source directories
      If ($cfg.paths.use_out_path) {
        If ($Null -eq (Get-ChildItem -Force $file.DirectoryName) -AND $file.DirectoryName -ne $cfg.paths.media) {
          Remove-Item $file.DirectoryName
        }
      }
    }
    Else {
      Add-Log "$($time.Invoke()) MP4 already compliant."
      If ($cfg.logging.use_ignore_list) {
        Add-Log "$($time.Invoke()) Added file to ignore list."
        $fileToIgnore = $file.BaseName + $file.Extension
        Add-IgnoreList "$($fileToIgnore)"
      }
    }

    #Running tally of session container duration (cumulative length of video processed)
    $script:cumulativeVideoDuration = $cumulativeVideoDuration + $getVideoDuration
  }
} # End foreach loop

#Wrap-up
Write-Statistics
Write-Failures
If ($cfg.cleanup.enable) {
  Remove-Garbage
}

Write-Output "`nFinished"

Remove-LockFile

Exit