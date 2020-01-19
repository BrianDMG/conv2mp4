<#======================================================================================================================
conv2mp4-ps v4.0 - https://github.com/BrianDMG/conv2mp4-ps

This Powershell script will recursively search through a user-defined file path and convert all videos of user-specified
filetypes to MP4 with H264 video and AAC audio using ffmpeg. If a conversion failure is detected, the script re-encodes
the file with HandbrakeCLI. Upon successful encoding, Plex libraries are (optionally) refreshed and source file is deleted.
The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server.
========================================================================================================================

ffmpeg : https://ffmpeg.org/download.html
handbrakecli : https://handbrake.fr/downloads.php #>

#Load properties file
$propFile = "$PSScriptRoot\files\prop\properties"
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
    $oldFile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;

    $fileSubDirs = ($file.DirectoryName).Substring($cfg.mediaPath.Length, ($file.DirectoryName).Length - $cfg.mediaPath.Length);
    If ($cfg.useOutPath) {
        $cfg.outPath = $baseOutPath + $fileSubDirs;

        If (-Not (Test-Path $cfg.outPath)) {
            mkdir $cfg.outPath
        }

        $newFile = $cfg.outPath + "\" + $file.BaseName + "_NEW" + ".mp4";
        Log "outPath = $($cfg.outPath)"
    }
    Else {
        $newFile = $file.DirectoryName + "\" + $file.BaseName + "_NEW" + ".mp4";
    }

    $progress = ($i / $fileCount) * 100
    $progress = [Math]::Round($progress,2)

    Log "$($prop.standard_divider)"
    Log "$($time.Invoke()) Processing - $oldFile"
    Log "$($time.Invoke()) File $i of $fileCount - Total queue $progress%"

    <#Test if $newFile (.mp4) already exists, if yes then delete $oldFile (.mkv)
    This outputs a more specific log message acknowleding the file already existed.#>
    $newFileRename = $file.DirectoryName + "\" + $file.BaseName + ".mp4";
    $testNewExist = Test-Path $newFileRename

    If ((Test-Path $testNewExist) -And $file.Extension -ne ".mp4") {
        Remove-Item $oldFile -Force
        Log "$($time.Invoke()) Already exists: $newFileRename"
        Log "$($time.Invoke()) Deleted: $oldFile."
    }
    Else {
        #Codec discovery to determine whether video, audio, or both needs to be encoded
        $script:aCodecCMD = Find-Codec -DiscoverType Audio
        $script:vCodecCMD = Find-Codec -DiscoverType Video
        $script:duration = Find-Codec -DiscoverType Duration

        #Statistics-gathering derived from Codec Discovery
        #Running tally of session container duration (cumulative length of video processed)
        $script:durTotal = $script:durTotal + $script:duration
        #Running tally of ticks (time expressed as an integer) for script runtime
        $script:durTicksTotal = $script:durTicksTotal + $script:durTicks

        #Begin ffmpeg conversion based on codec discovery

        # Video is already H264, Audio is already AAC
        If ($vCodecCMD -eq 'h264' -AND $aCodecCMD -eq 'aac') {
            If ($file.Extension -ne ".mp4") {
                Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Performing simple container conversion to MP4."
                ConvertToNewMP4 -ConvertType Simple -KeepSubs:$cfg.keepSubs
                $skipFile = $False
            }
            Else {
                $skipFile = $True
            }
        }
        # Video is already H264, Audio is not AAC
        ElseIf ($vCodecCMD -eq 'h264' -AND $aCodecCMD -ne 'aac') {
            Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding audio to AAC"
            ConvertToNewMP4 -ConvertType Audio -KeepSubs:$cfg.keepSubs
            $skipFile = $False
        }
        # Video is not H264, Audio is already AAC
        ElseIf ($vCodecCMD -ne 'h264' -AND $aCodecCMD -eq 'aac') {
            Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding video to H264."
            ConvertToNewMP4 -ConvertType Video -KeepSubs:$cfg.keepSubs
            $skipFile = $False
        }
        # Video is not H264, Audio is not AAC
        ElseIf ($vCodecCMD -ne 'h264' -AND $aCodecCMD -ne 'aac') {
            Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding video to H264 and audio to AAC."
            ConvertToNewMP4 -ConvertType Both -KeepSubs:$cfg.keepSubs
            $skipFile = $False
        }

        # Refresh Plex libraries
        If ($cfg.usePlex) {
            # Refresh Plex libraries
            PlexRefresh
        }

        #Begin file comparison between old file and new file to determine conversion success
        If ($skipFile -eq $False) {

            $fileOld = Get-Item $oldFile
            $fileNew = Get-Item $newFile

            # If new file is the same size as old file, log status and delete old file
            If ($fileNew.length -eq $fileOld.length) {
                IfSame
            }

            # If new file is larger than old file, log status and delete old file
            Elseif ($fileNew.length -gt $fileOld.length) {
                IfLarger
            }
            # If new file is much smaller than old file (indicating a failed conversion), log status, delete new file, and re-encode with HandbrakeCLI
            Elseif ($fileNew.length -lt ($fileOld.length * $cfg.failOverThresh)) {
                FailureDetected

                #Begin Handbrake encode (lossy)
                ConvertToNewMP4 -ConvertType Handbrake -KeepSubs:$cfg.keepSubs

                # Load files for comparison
                $fileOld = Get-Item $oldFile
                $fileNew = Get-Item $newFile

                # If new file is much smaller than old file (likely because the script was aborted re-encode), leave original file alone and print error
                If ($fileNew.length -lt ($fileOld.length * $cfg.failOverThresh)) {
                    $diffErr = [Math]::Round($fileNew.length - $fileOld.length)/1MB
                    $diffErr = [Math]::Round($diffErr, 2)

                    Try {
                        Remove-Item $newFile -Force -ErrorAction Stop
                        Log "$($time.Invoke()) ERROR: New file was too small ($($diffErr)MB)."
                        Log "$($time.Invoke()) Deleted new file and retained $oldFile."
                    }
                    Catch {
                        Log "$($time.Invoke()) ERROR: New file was too small ($($diffErr)MB). Retained $oldFile."
                        Log "$($time.Invoke()) ERROR: $newFile could not be deleted. Full error below."
                        Log $_
                    }
                }

                # If new file is the same size as old file, log status and delete old file
                Elseif ($fileNew.length -eq $fileOld.length) {
                    IfSame
                }

                # If new file is larger than old file, log status and delete old file
                Elseif ($fileNew.length -gt $fileOld.length) {
                    IfLarger
                }

                # If new file is smaller than old file, log status and delete old file
                Elseif ($fileNew.length -lt $fileOld.length) {
                    IfSmaller
                }
            }

            # If new file is smaller than old file, log status and delete old file
            Elseif ($fileNew.length -lt $fileOld.length) {
                IfSmaller
            }

            #If $oldFile was an mp4, rename $newFile to remove "-NEW"
            $newFileRename = "$newFile" -replace "_NEW",""
            Move-Item $newFile $newFileRename

        }
        Else {
            Log "$($time.Invoke()) MP4 already compliant."
            If ($cfg.useIgnore -eq $True) {
                Log "$($time.Invoke()) Added file to ignore list."
                $addIgnore = $file.BaseName + $file.Extension;
                AddIgnore "$($addIgnore)"
            }
        }
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
