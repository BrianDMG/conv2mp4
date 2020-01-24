<#======================================================================================================================
conv2mp4-ps v4.0 - https://github.com/BrianDMG/conv2mp4-ps

This Powershell script will recursively search through a user-defined file path and convert all videos of user-specified
include_file_types to MP4 with H264 video and AAC audio using ffmpeg. If a conversion failure is detected, the script re-encodes
the file with HandbrakeCLI. Upon successful encoding, Plex libraries are (optionally) refreshed and source file is deleted.
The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server.
========================================================================================================================#>

Set-Location -Path $PSScriptRoot

#Load properties file
$propFile = "files\prop\properties"
$propRawString = Get-Content "$propFile" | Out-String
$propStringToConvert = $propRawString -replace '\\', '\\'
$prop = ConvertFrom-StringData $propStringToConvert

#Load configuration
$cfgRawString = Get-Content "$($prop.cfg_path)" | Out-String
$cfgStringToConvert = $cfgRawString -replace '\\', '\\'
$cfg = ConvertFrom-StringData $cfgStringToConvert

#Initialize script
. $prop.init

#Execute preflight checks
. $prop.preflight

#Build processing queue and list its contents
. $prop.buildqueue

# Begin performing operations of files
$i = 0

ForEach ($file in $fileList) {
    $i++;
    $title = $file.BaseName
    $sourceFile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;

    $fileSubDirs = ($file.DirectoryName).Substring($cfg.media_path.Length, ($file.DirectoryName).Length - $cfg.media_path.Length);
    If ($cfg.use_out_path) {
        $cfg.out_path = $baseout_path + $fileSubDirs;

        If (-Not (Test-Path $cfg.out_path)) {
            mkdir $cfg.out_path
        }

        $targetFile = $cfg.out_path + "\" + $file.BaseName + "_NEW" + ".mp4";
        Log "out_path = $($cfg.out_path)"
    }
    Else {
        $targetFile = $file.DirectoryName + "\" + $file.BaseName + "_NEW" + ".mp4";
    }

    $progress = ($i / $fileCount) * 100
    $progress = [Math]::Round($progress,2)

    Write-Progress -Activity "$sourceFile" -PercentComplete $progress -CurrentOperation "$($progress)% Complete"

    Log "$($prop.standard_divider)"
    Log "$($time.Invoke()) Processing - $sourceFile"
    Log "$($time.Invoke()) File $i of $fileCount - Total queue $progress%"

    <#Test if $targetFile (.mp4) already exists, if yes then delete $sourceFile (.mkv)
    This outputs a more specific log message acknowleding the file already existed.#>
    $targetFileRenamed = $file.DirectoryName + "\" + $file.BaseName + ".mp4"

    If ((Test-Path $targetFileRenamed) -And $file.Extension -ne ".mp4") {
        Remove-Item $sourceFile -Force
        Log "$($time.Invoke()) Already exists: $targetFileRenamed"
        Log "$($time.Invoke()) Deleted: $sourceFile."
    }
    Else {
        #Codec discovery to determine whether video, audio, or both needs to be encoded
        $getAudioCodec = GetCodec -DiscoverType Audio
        $getVideoCodec = GetCodec -DiscoverType Video
        $getVideoDuration = GetCodec -DiscoverType Duration

        # Video is already H264, Audio is already AAC
        If ($getVideoCodec -eq 'h264' -AND $getAudioCodec -eq 'aac') {
            If ($file.Extension -ne ".mp4") {
                Log "$($time.Invoke()) Video: $($getVideoCodec.ToUpper()), Audio: $($getAudioCodec.ToUpper()). Performing simple container conversion to MP4."
                ConvertFile -ConvertType Simple -KeepSubs:$cfg.keep_subtitles
                $skipFile = $False
            }
            Else {
                $getVideoDuration = "00:00:00"
                $skipFile = $True
            }
        }
        # Video is already H264, Audio is not AAC
        ElseIf ($getVideoCodec -eq 'h264' -AND $getAudioCodec -ne 'aac') {
            Log "$($time.Invoke()) Video: $($getVideoCodec.ToUpper()), Audio: $($getAudioCodec.ToUpper()). Encoding audio to AAC"
            ConvertFile -ConvertType Audio -KeepSubs:$cfg.keep_subtitles
            $skipFile = $False
        }
        # Video is not H264, Audio is already AAC
        ElseIf ($getVideoCodec -ne 'h264' -AND $getAudioCodec -eq 'aac') {
            Log "$($time.Invoke()) Video: $($getVideoCodec.ToUpper()), Audio: $($getAudioCodec.ToUpper()). Encoding video to H264."
            ConvertFile -ConvertType Video -KeepSubs:$cfg.keep_subtitles
            $skipFile = $False
        }
        # Video is not H264, Audio is not AAC
        ElseIf ($getVideoCodec -ne 'h264' -AND $getAudioCodec -ne 'aac') {
            Log "$($time.Invoke()) Video: $($getVideoCodec.ToUpper()), Audio: $($getAudioCodec.ToUpper()). Encoding video to H264 and audio to AAC."
            ConvertFile -ConvertType Both -KeepSubs:$cfg.keep_subtitles
            $skipFile = $False
        }

        If ($cfg.force_stereo_clone -eq $True) {
            CloneStereoStream
        }

        # Refresh Plex libraries
        If ($cfg.use_plex) {
            PlexRefresh
        }

        #Begin file comparison between old file and new file to determine conversion success
        If ($skipFile -eq $False) {

            $sourceFileCompare = Get-Item $sourceFile
            $targetFileCompare = Get-Item $targetFile

            # If new file is the same size as old file, log status and delete old file
            If ($targetFileCompare.length -eq $sourceFileCompare.length) {
                CompareIfSame
            }

            # If new file is larger than old file, log status and delete old file
            Elseif ($targetFileCompare.length -gt $sourceFileCompare.length) {
                CompareIfLarger
            }
            # If new file is much smaller than old file (indicating a failed conversion), log status, delete new file, and re-encode with HandbrakeCLI
            Elseif ($targetFileCompare.length -lt ($sourceFileCompare.length * $cfg.failover_threshold)) {
                PrintEncodeError

                #Begin Handbrake encode (lossy)
                ConvertFile -ConvertType Handbrake -KeepSubs:$cfg.keep_subtitles

                # Load files for comparison
                $sourceFileCompare = Get-Item $sourceFile
                $targetFileCompare = Get-Item $targetFile

                # If new file is much smaller than old file (likely because the script was aborted re-encode), leave original file alone and print error
                If ($targetFileCompare.length -lt ($sourceFileCompare.length * $cfg.failover_threshold)) {
                    $fileSizeDelta = [Math]::Round($targetFileCompare.length - $sourceFileCompare.length)/1MB
                    $fileSizeDelta = [Math]::Round($fileSizeDelta, 2)

                    Try {
                        Remove-Item $targetFile -Force -ErrorAction Stop
                        Log "$($time.Invoke()) ERROR: New file was too small ($($fileSizeDelta)MB)."
                        Log "$($time.Invoke()) Deleted new file and retained $sourceFile."
                    }
                    Catch {
                        Log "$($time.Invoke()) ERROR: New file was too small ($($fileSizeDelta)MB). Retained $sourceFile."
                        Log "$($time.Invoke()) ERROR: $targetFile could not be deleted. Full error below."
                        Log $_
                    }
                }

                # If new file is the same size as old file, log status and delete old file
                Elseif ($targetFileCompare.length -eq $sourceFileCompare.length) {
                    CompareIfSame
                }

                # If new file is larger than old file, log status and delete old file
                Elseif ($targetFileCompare.length -gt $sourceFileCompare.length) {
                    CompareIfLarger
                }

                # If new file is smaller than old file, log status and delete old file
                Elseif ($targetFileCompare.length -lt $sourceFileCompare.length) {
                    CompareIfSmaller
                }
            }

            # If new file is smaller than old file, log status and delete old file
            Elseif ($targetFileCompare.length -lt $sourceFileCompare.length) {
                CompareIfSmaller
            }

            #If $sourceFile was an mp4, rename $targetFile to remove "-NEW"
            $targetFileRenamed = "$targetFile" -replace "_NEW",""
            Move-Item $targetFile $targetFileRenamed

        }
        Else {
            Log "$($time.Invoke()) MP4 already compliant."
            If ($cfg.use_ignore_list -eq $True) {
                Log "$($time.Invoke()) Added file to ignore list."
                $fileToIgnore = $file.BaseName + $file.Extension;
                AddToIgnoreList "$($fileToIgnore)"
            }
        }

        #Running tally of session container duration (cumulative length of video processed)
        $script:cumulativeVideoDuration = $script:cumulativeVideoDuration + $getVideoDuration
    }
} # End foreach loop

#Wrap-up
PrintStatistics
If ($cfg.collect_garbage) {
    CollectGarbage
}

Log "`nFinished"

DeleteLockFile

Exit
