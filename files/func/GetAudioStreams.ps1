Function GetAudioStreams {
    $ffprobe = Join-Path $cfg.fmmpeg_bin_dir "ffprobe.exe"

    $ffprobeArgs += "-v "
    $ffprobeArgs += "error "
    $ffprobeArgs += "`"$targetFile`" "
    $ffprobeArgs += "-show_entries "
    $ffprobeArgs += "stream=channels "
    $ffprobeArgs += "-select_streams "
    $ffprobeArgs += "a "
    $ffprobeArgs += "-of "
    $ffprobeArgs += "compact=p=0:nk=1"

    [int[]] $audioStreamArray = cmd.exe /c "`"$ffprobe`" $ffprobeArgs"

    #If last channel is not stereo, create one
    If ($audioStreamArray[$audioStreamArray.Length-1] -gt 2 ) {
        return $True
    }
    #If not, skip stream clone
    Else {
        return $False
    }
}