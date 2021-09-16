Function Copy-StereoStream {

  $copyStereo = Get-AudioStreams

  #If no stereo channel exists, create one
  If ($copyStereo) {
    New-Item -Path $($prop.paths.temp.dir) -ItemType 'directory' -Force

    $ffmpeg = Join-Path $cfg.paths.ffmpeg 'ffmpeg'

    $audioCloneFileBaseName = $file.BaseName + '.mp4.conv2mp4.stere_clone'
    $audioCloneFileRenamed = $targetFile + '.stereo_clone'

    $surroundChannelAudioFilePath = Join-Path $prop.paths.temp.dir $prop.paths.temp.tmp_51out
    $stereoChannelAudioFilePath = Join-Path $prop.paths.temp.dir $prop.paths.temp.tmp_2in

    #ffmpeg pull audio track from file
    $ffmpegArgs = "-i "
    If ( $targetFile.Contains("'") ) {
      $ffmpegArgs += "`"$($targetFile)`" " #Output file
    }
    Else {
      $ffmpegArgs += "`'$($targetFile)`' " #Output file
    }
    $ffmpegArgs += "-vn "
    $ffmpegArgs += "-acodec "
    $ffmpegArgs += "copy "
    $ffmpegArgs += "$($surroundChannelAudioFilePath)"
    $ffmpegCMD = Invoke-Expression -Command "$($ffmpeg) $($ffmpegArgs)"

    #ffmpeg convert audio track
    $ffmpegArgs = "-i "
    $ffmpegArgs += "$($surroundChannelAudioFilePath) "
    $ffmpegArgs += "-ac "
    $ffmpegArgs += "2 "
    $ffmpegArgs += "$($stereoChannelAudioFilePath)"
    $ffmpegCMD = Invoke-Expression -Command "$($ffmpeg) $($ffmpegArgs)"


    #Rename original source file, necessary to avoid corrupting by using same file as input and output
    Rename-Item $targetFile $audioCloneFileRenamed -Force

    #ffmpeg inject stereo audio track back into file
    $ffmpegArgs = "-y "
    $ffmpegArgs += "-i "
    $ffmpegArgs += "$($audioCloneFileRenamed) "
    $ffmpegArgs += "-i "
    $ffmpegArgs += "$($stereoChannelAudioFilePath) "
    $ffmpegArgs += "-map "
    $ffmpegArgs += "0 "
    $ffmpegArgs += "-map "
    $ffmpegArgs += "1 "
    $ffmpegArgs += "-c "
    $ffmpegArgs += "copy "
    $ffmpegArgs += "-metadata:s:a "
    $ffmpegArgs += "handler=Stereo "
    $ffmpegArgs += "-f "
    $ffmpegArgs += "mp4 "
    If ( $targetFile.Contains("'") ) {
      $ffmpegArgs += "`"$($targetFile)`"" #Output file
    }
    Else {
      $ffmpegArgs += "`'$($targetFile)`'" #Output file
    }
    $ffmpegCMD = Invoke-Expression -Command "$($ffmpeg) $($ffmpegArgs)"

    Remove-Item "$($audioCloneFileRenamed)" -Force
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