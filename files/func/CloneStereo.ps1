Function CloneStereo {

    Write-Output "Finding audio channels"
    $copyStereo = FindAudioStreams

    #If no stereo channel exists, create one
    If ($copyStereo) {
        write-output "`nWe're converting"
        mkdir $($prop.temp_dir) -Force
        Write-Output "Extract audio"
        #ffmpeg pull audio track from file
        $ffmpegArgs = "-i "
        $ffmpegArgs += "$newFileRenamed "
        $ffmpegArgs += "-vn "
        $ffmpegArgs += "-acodec "
        $ffmpegArgs += "copy "
        $ffmpegArgs += "$($prop.temp_dir)\$($prop.temp_51out)"
        $ffmpegCMD = cmd.exe /c "$ffmpeg $ffmpegArgs"

        Write-Output "Convert audio"
        #ffmpeg convert audio track
        $ffmpegArgs = "-i "
        $ffmpegArgs += "$($prop.temp_dir)\$($prop.temp_51out) "
        $ffmpegArgs += "-ac "
        $ffmpegArgs += "2 "
        $ffmpegArgs += "$($prop.temp_dir)\$($prop.temp_2in)"
        $ffmpegCMD = cmd.exe /c "$ffmpeg $ffmpegArgs"

        Write-Output "Inject audio"
        #ffmpeg inject stereo audio track back into file
        $ffmpegArgs = "-y "
        $ffmpegArgs += "-i "
        $ffmpegArgs += "$newFileRenamed "
        $ffmpegArgs += "-i "
        $ffmpegArgs += "$($prop.temp_dir)\$($prop.temp_2in) "
        $ffmpegArgs += "-map "
        $ffmpegArgs += "0 "
        $ffmpegArgs += "-map "
        $ffmpegArgs += "1 "
        $ffmpegArgs += "-codec "
        $ffmpegArgs += "copy "
        $ffmpegArgs += "$newFileRenamed"
        $ffmpegCMD = cmd.exe /c "$ffmpeg $ffmpegArgs"

        Write-Output "Delete temp files"
        Remove-Item $prop.temp_dir -Force -Recurse

        Write-Output "Verify success"
        $copyStereo = FindAudioStreams
        If ($copyStereo) {
            Log "Audio add failed"
            DeleteLockFile
            Exit
        }
        Else {
            Write-Output "Copy successful, moving on.."
        }
    }
    Else {
        Write-Output "`nAlready has stereo channel"
    }
}