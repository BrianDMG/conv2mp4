<#======================================================================================================================
conv2mp4-ps v4.0 - https://github.com/BrianDMG/conv2mp4-ps

This Powershell script will recursively search through a user-defined file path and convert all videos of user-specified
filetypes to MP4 with H264 video and AAC audio using ffmpeg. If a conversion failure is detected, the script re-encodes
the file with HandbrakeCLI. Upon successful encoding, Plex libraries are (optionally) refreshed and source file is deleted.
The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server.
========================================================================================================================

ffmpeg : https://ffmpeg.org/download.html
handbrakecli : https://handbrake.fr/downloads.php #>

Set-Location -Path $PSScriptRoot

#Load properties file
$propFile = "files\prop\properties"
$propRawString = Get-Content "$propFile" | Out-String
$propStringToConvert = $propRawString -replace '\\', '\\'
$prop = ConvertFrom-StringData $propStringToConvert

#Load configuration
. $prop.loadcfg

#Initialize script
. $prop.init

#Execute preflight checks
. $prop.preflight

# Print initial wait notice to console
Write-Output "`nBuilding file list, please wait. This may take a while, especially for large libraries.`n"

#Build processing queue and list its contents
. $prop.buildqueue

# Begin performing operations of files
$i = 0

ForEach ($file in $fileList) {
    $i++;
    $title = $file.BaseName
    $sourceFile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;

    $fileSubDirs = ($file.DirectoryName).Substring($cfg.mediaPath.Length, ($file.DirectoryName).Length - $cfg.mediaPath.Length);
    If ($cfg.useOutPath) {
        $cfg.outPath = $baseOutPath + $fileSubDirs;

        If (-Not (Test-Path $cfg.outPath)) {
            mkdir $cfg.outPath
        }

        $targetFile = $cfg.outPath + "\" + $file.BaseName + "_NEW" + ".mp4";
        Log "outPath = $($cfg.outPath)"
    }
    Else {
        $targetFile = $file.DirectoryName + "\" + $file.BaseName + "_NEW" + ".mp4";
    }

    $progress = ($i / $fileCount) * 100
    $progress = [Math]::Round($progress,2)

    Write-Progress -ACtivity "$sourceFile" -PercentComplete $progress -CurrentOperation "$($progress)% Complete"

    Log "$($prop.standard_divider)"
    Log "$($time.Invoke()) Processing - $sourceFile"
    Log "$($time.Invoke()) File $i of $fileCount - Total queue $progress%"

    <#Test if $targetFile (.mp4) already exists, if yes then delete $sourceFile (.mkv)
    This outputs a more specific log message acknowleding the file already existed.#>
    $targetFileRenamed = $file.DirectoryName + "\" + $file.BaseName + ".mp4"
    $targetFileRenamed
    $testIfNewExist = Test-Path $targetFileRenamed
    $testIfNewExist
    $file.Extension
    If (($testIfNewExist) -And $file.Extension -ne ".mp4") {
        Remove-Item $sourceFile -Force
        Log "$($time.Invoke()) Already exists: $targetFileRenamed"
        Log "$($time.Invoke()) Deleted: $sourceFile."
    }
    Else {
        #Codec discovery to determine whether video, audio, or both needs to be encoded
        $getAudioCodec = GetCodec -DiscoverType Audio
        $getVideoCodec = GetCodec -DiscoverType Video
        $getVideoDuration = GetCodec -DiscoverType Duration
        #Statistics-gathering derived from Codec Discovery

        #Begin ffmpeg conversion based on codec discovery

        # Video is already H264, Audio is already AAC
        If ($getVideoCodec -eq 'h264' -AND $getAudioCodec -eq 'aac') {
            If ($file.Extension -ne ".mp4") {
                Log "$($time.Invoke()) Video: $($script:getVideoCodec.ToUpper()), Audio: $($script:getAudioCodec.ToUpper()). Performing simple container conversion to MP4."
                ConvertToNewMP4 -ConvertType Simple -KeepSubs:$cfg.keepSubs
                $skipFile = $False
            }
            Else {
                $getVideoDuration = "00:00:00"
                $skipFile = $True
            }
        }
        # Video is already H264, Audio is not AAC
        ElseIf ($getVideoCodec -eq 'h264' -AND $getAudioCodec -ne 'aac') {
            Log "$($time.Invoke()) Video: $($script:getVideoCodec.ToUpper()), Audio: $($script:getAudioCodec.ToUpper()). Encoding audio to AAC"
            ConvertToNewMP4 -ConvertType Audio -KeepSubs:$cfg.keepSubs
            $skipFile = $False
        }
        # Video is not H264, Audio is already AAC
        ElseIf ($getVideoCodec -ne 'h264' -AND $getAudioCodec -eq 'aac') {
            Log "$($time.Invoke()) Video: $($script:getVideoCodec.ToUpper()), Audio: $($script:getAudioCodec.ToUpper()). Encoding video to H264."
            ConvertToNewMP4 -ConvertType Video -KeepSubs:$cfg.keepSubs
            $skipFile = $False
        }
        # Video is not H264, Audio is not AAC
        ElseIf ($getVideoCodec -ne 'h264' -AND $getAudioCodec -ne 'aac') {
            Log "$($time.Invoke()) Video: $($script:getVideoCodec.ToUpper()), Audio: $($script:getAudioCodec.ToUpper()). Encoding video to H264 and audio to AAC."
            ConvertToNewMP4 -ConvertType Both -KeepSubs:$cfg.keepSubs
            $skipFile = $False
        }

        If ($cfg.force2chCopy -eq $True) {
            CloneStereo
        }

        # Refresh Plex libraries
        If ($cfg.usePlex) {
            # Refresh Plex libraries
            PlexRefresh
        }

        #Begin file comparison between old file and new file to determine conversion success
        If ($skipFile -eq $False) {

            $sourceFileCompare = Get-Item $sourceFile
            $targetFileCompare = Get-Item $targetFile

            # If new file is the same size as old file, log status and delete old file
            If ($targetFileCompare.length -eq $sourceFileCompare.length) {
                IfSame
            }

            # If new file is larger than old file, log status and delete old file
            Elseif ($targetFileCompare.length -gt $sourceFileCompare.length) {
                IfLarger
            }
            # If new file is much smaller than old file (indicating a failed conversion), log status, delete new file, and re-encode with HandbrakeCLI
            Elseif ($targetFileCompare.length -lt ($sourceFileCompare.length * $cfg.failOverThresh)) {
                FailureDetected

                #Begin Handbrake encode (lossy)
                ConvertToNewMP4 -ConvertType Handbrake -KeepSubs:$cfg.keepSubs

                # Load files for comparison
                $sourceFileCompare = Get-Item $sourceFile
                $targetFileCompare = Get-Item $targetFile

                # If new file is much smaller than old file (likely because the script was aborted re-encode), leave original file alone and print error
                If ($targetFileCompare.length -lt ($sourceFileCompare.length * $cfg.failOverThresh)) {
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
                    IfSame
                }

                # If new file is larger than old file, log status and delete old file
                Elseif ($targetFileCompare.length -gt $sourceFileCompare.length) {
                    IfLarger
                }

                # If new file is smaller than old file, log status and delete old file
                Elseif ($targetFileCompare.length -lt $sourceFileCompare.length) {
                    IfSmaller
                }
            }

            # If new file is smaller than old file, log status and delete old file
            Elseif ($targetFileCompare.length -lt $sourceFileCompare.length) {
                IfSmaller
            }

            #If $sourceFile was an mp4, rename $targetFile to remove "-NEW"
            $targetFileRenamed = "$targetFile" -replace "_NEW",""
            Move-Item $targetFile $targetFileRenamed

        }
        Else {
            Log "$($time.Invoke()) MP4 already compliant."
            If ($cfg.useIgnore -eq $True) {
                Log "$($time.Invoke()) Added file to ignore list."
                $fileToIgnore = $file.BaseName + $file.Extension;
                AddIgnore "$($fileToIgnore)"
            }
        }

        #Running tally of session container duration (cumulative length of video processed)
        $script:cumulativeVideoDuration = $script:cumulativeVideoDuration + $getVideoDuration
    }
} # End foreach loop

#Wrap-up
FinalStatistics
If ($cfg.collectGarbage) {
    GarbageCollection
}

Log "`nFinished"

DeleteLockFile

Exit
