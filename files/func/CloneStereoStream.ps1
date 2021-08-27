Function CloneStereoStream {

    $copyStereo = GetAudioStreams

    $tempFileName=$file.DirectoryName + "\" + $file.BaseName + "_TEMP" + ".mp4"

    #If no stereo channel exists, create one
    If ($copyStereo) {
        mkdir $($prop.tmp_dir) -Force

        $ffmpeg = Join-Path $cfg.ffmpeg_bin_dir "ffmpeg.exe"

        #ffmpeg pull audio track from file
        $ffmpegArgs = "-i "
        $ffmpegArgs += "$targetFile "
        $ffmpegArgs += "-vn "
        $ffmpegArgs += "-acodec "
        $ffmpegArgs += "copy "
        $ffmpegArgs += "$($prop.tmp_dir)\$($prop.tmp_51out)"
        $ffmpegCMD = "`"$ffmpeg`" $ffmpegArgs"

        #ffmpeg convert audio track
        $ffmpegArgs = "-i "
        $ffmpegArgs += "$($prop.tmp_dir)\$($prop.tmp_51out) "
        $ffmpegArgs += "-ac "
        $ffmpegArgs += "2 "
        $ffmpegArgs += "$($prop.tmp_dir)\$($prop.tmp_2in)"
        $ffmpegCMD = "`"$ffmpeg`" $ffmpegArgs"

        #Rename original source file, necessary to avoid corrupting by using same file as input and output
        Move-Item $targetFile $tempFileName -Force

        #ffmpeg inject stereo audio track back into file
        $ffmpegArgs = "-y "
        $ffmpegArgs += "-i "
        $ffmpegArgs += "$tempFileName "
        $ffmpegArgs += "-i "
        $ffmpegArgs += "$($prop.tmp_dir)\$($prop.tmp_2in) "
        $ffmpegArgs += "-map "
        $ffmpegArgs += "0 "
        $ffmpegArgs += "-map "
        $ffmpegArgs += "1 "
        $ffmpegArgs += "-c "
        $ffmpegArgs += "copy "
        $ffmpegArgs += "-metadata:s:a "
        $ffmpegArgs += "handler=Stereo "
        $ffmpegArgs += "$targetFile"
        $ffmpegCMD = "`"$ffmpeg`" $ffmpegArgs"

        Remove-Item $tempFileName -Force
        Remove-Item $prop.tmp_dir -Force -Recurse

        $copyStereo = GetAudioStreams
        If ($copyStereo) {
            Log "Audio add failed"
            DeleteLockFile
            Exit
        }
        Else {
            Log "$($time.Invoke()) Appended a stereo audio stream."
        }
    }
}