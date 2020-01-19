# Find out what video and audio codecs a file is using
Function Find-Codec {
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
            #Pass this value down to the next If/Else
            $ffprobeTemp = 0
        }
        Else {
            $ffprobeTemp = [timespan]::fromseconds($ffprobeCMD)
            $script:durTicks = $ffprobeTemp.ticks
        }

        #Test whether the ffprobe results was invalid AFTER conversion into time format
        If ($ffprobeTemp -eq 0 -OR $ffprobeTemp -eq 'N/A') {
            return "00:00:00"
        }
        Else {
            return "$($ffprobeTemp.hours):$($ffprobeTemp.minutes):$($ffprobeTemp.seconds)"
        }
    }
    Else {
        return $ffprobeCMD
    }
}