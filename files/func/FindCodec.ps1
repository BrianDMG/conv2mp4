# Find out what video and audio codecs a file is using
Function FindCodec {
    param
    (
        [Parameter(Position = 0, mandatory = $True)]
        [ValidateSet("Audio", "Video", "Duration")]
        [String]$DiscoverType
    )

    # Check video codec with ffprobe
    $ffprobeArgs += "-v "
    $ffprobeArgs += "error "

    If ($DiscoverType -eq "Video") {
        $ffprobeArgs += "-select_streams "
        $ffprobeArgs += "v:0 "
        $ffprobeArgs += "-show_entries "
        $ffprobeArgs += "stream=codec_name "
    }

    If ($DiscoverType -eq "Audio") {
        $ffprobeArgs += "-v "
        $ffprobeArgs += "error "
        $ffprobeArgs += "-select_streams "
        $ffprobeArgs += "a:0 "
        $ffprobeArgs += "-show_entries "
        $ffprobeArgs += "stream=codec_name "
    }

    If ($DiscoverType -eq "Duration") {
        $ffprobeArgs += "-v "
        $ffprobeArgs += "error "
        $ffprobeArgs += "-show_entries "
        $ffprobeArgs += "format=duration "
    }

    $ffprobeArgs += "-of "
    $ffprobeArgs += "default=noprint_wrappers=1:nokey=1 "
    $ffprobeArgs += "`"$oldFile`""

    $ffprobeCMD = cmd.exe /c "$ffprobe $ffprobeArgs"

    If ($DiscoverType -eq "Duration") {
        #Test whether the ffprobe result was invalid - usually happens in files with corrupt encoding
        If ($ffprobeCMD -eq 0 -OR $ffprobeCMD -eq 'N/A') {
            $vidDuration=[timespan]::fromseconds(0)
            return "$($vidDuration.hours):$($vidDuration.minutes):$($vidDuration.seconds)"
        }
        ElseIf ($aCodecCMD -eq 'aac' -AND $vCodecCMD -eq 'h264' -AND $oldFile.Extension -eq '.mp4') {
            $vidDuration=[timespan]::fromseconds(0)
            return "$($vidDuration.hours):$($vidDuration.minutes):$($vidDuration.seconds)"
        }
        Else {
            $vidDuration=[timespan]::fromseconds($ffprobeCMD)
            return "$($vidDuration.hours):$($vidDuration.minutes):$($vidDuration.seconds)"
        }
    }
    Else {
        #Returns video and audio codec information
        return $ffprobeCMD
    }
}