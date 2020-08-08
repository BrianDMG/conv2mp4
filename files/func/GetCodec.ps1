# Find out what video and audio codecs a file is using
Function GetCodec {
    param
    (
        [Parameter(Position = 0, mandatory = $True)]
        [ValidateSet("Audio", "Video", "Duration")]
        [String]$DiscoverType
    )

    $bin = 'ffprobe'

    If ($isWindows) {
        $bin = $bin + '.exe'
    }

    $ffprobe = Convert-Path "$($cfg.ffmpeg_bin_dir)\$($bin)"

    # Check codec with ffprobe
    $ffprobeArgs += "-v "
    $ffprobeArgs += "error "

    If ($DiscoverType -eq "Video") {
        $ffprobeArgs += "-select_streams "
        $ffprobeArgs += "v:0 "
        $ffprobeArgs += "-show_entries "
        $ffprobeArgs += "stream=codec_name "
    }

    If ($DiscoverType -eq "Audio") {
        $ffprobeArgs += "-select_streams "
        $ffprobeArgs += "a:0 "
        $ffprobeArgs += "-show_entries "
        $ffprobeArgs += "stream=codec_name "
    }

    If ($DiscoverType -eq "Duration") {
        $ffprobeArgs += "-show_entries "
        $ffprobeArgs += "format=duration "
    }

    $ffprobeArgs += "-of "
    $ffprobeArgs += "default=noprint_wrappers=1:nokey=1 "
    $ffprobeArgs += "`"$sourceFile`""

    If ($isWindows) {
        $ffprobeCMD = cmd.exe /c "`"$ffprobe`" $ffprobeArgs"
    }
    Else {
        $ffprobeCMD = /bin/bash -c "`"$ffprobe`" $ffprobeArgs"
    }

    If ($DiscoverType -eq "Duration") {
        #Test whether the ffprobe result was invalid - usually happens in files with corrupt encoding
        If ($ffprobeCMD -eq 0 -OR $ffprobeCMD -eq 'N/A' -OR !$getAudioCodec -OR !$getVideoCodec) {
            $currentVideoDuration=[timespan]::fromseconds(0)
            return "$($currentVideoDuration.hours):$($currentVideoDuration.minutes):$($currentVideoDuration.seconds)"
        }
        Else {
            $currentVideoDuration=[timespan]::fromseconds($ffprobeCMD)
            return "$($currentVideoDuration.hours):$($currentVideoDuration.minutes):$($currentVideoDuration.seconds)"
        }
    }
    Else {
        #Returns video and audio codec information
        return $ffprobeCMD
    }
}