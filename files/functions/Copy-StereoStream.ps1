Function Copy-StereoStream {

  $copyStereo = Get-AudioStreams

  $tempFileName=$file.DirectoryName + "\" + $file.BaseName + "_TEMP" + ".mp4"

  #If no stereo channel exists, create one
  If ($copyStereo) {
    New-Item -Path $($prop.paths.temp.dir) -Force

    $ffmpeg = Join-Path $cfg.paths.ffmpeg "ffmpeg.exe"

    #ffmpeg pull audio track from file
    $ffmpegArgs = "-i "
    $ffmpegArgs += "$targetFile "
    $ffmpegArgs += "-vn "
    $ffmpegArgs += "-acodec "
    $ffmpegArgs += "copy "
    $ffmpegArgs += "$($prop.paths.temp.dir)\$($prop.paths.temp.tmp_51out)"
    $ffmpegCMD = "`"$ffmpeg`" $ffmpegArgs"

    #ffmpeg convert audio track
    $ffmpegArgs = "-i "
    $ffmpegArgs += "$($prop.paths.temp.dir)\$($prop.paths.temp.tmp_51out) "
    $ffmpegArgs += "-ac "
    $ffmpegArgs += "2 "
    $ffmpegArgs += "$($prop.paths.temp.dir)\$($prop.paths.temp.tmp_2in)"
    $ffmpegCMD = "`"$ffmpeg`" $ffmpegArgs"

    #Rename original source file, necessary to avoid corrupting by using same file as input and output
    Move-Item $targetFile $tempFileName -Force

    #ffmpeg inject stereo audio track back into file
    $ffmpegArgs = "-y "
    $ffmpegArgs += "-i "
    $ffmpegArgs += "$tempFileName "
    $ffmpegArgs += "-i "
    $ffmpegArgs += "$($prop.paths.temp.dir)\$($prop.paths.temp.tmp_2in) "
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
    Remove-Item $prop.paths.temp.dir -Force -Recurse

    $copyStereo = Get-AudioStreams
    If ($copyStereo) {
      Add-Log "Audio add failed"
      Remove-LockFile
      Exit
    }
    Else {
      Add-Log "$($time.Invoke()) Appended a stereo audio stream."
    }
  }
}