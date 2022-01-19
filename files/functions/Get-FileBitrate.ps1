Function Get-FileBitrate {

  Param(
    [String]$File
  )

  $bin = 'ffprobe'

  If ($IsWindows) {
    $bin = $bin + '.exe'
  }

  $ffprobe = Convert-Path $(Join-Path "$($cfg.paths.ffmpeg)" "$($bin)")

  $singleQuoteRegex = @("'","‘","’","´")
  $containsSingleQuote = $null -ne ( $singleQuoteRegex | ? { $sourceFile -match $_ } )

  # Get video/audio bitrates with ffprobe
  $ffprobeArgs += "-v "
  $ffprobeArgs += "error "
  $ffprobeArgs += "-show_entries "
  $ffprobeArgs += "stream=bit_rate "
  $ffprobeArgs += "-hide_banner "
  $ffprobeArgs += "-of "
  $ffprobeArgs += "compact=p=0:nk=1 "
  $ffprobeArgs += "-print_format "
  $ffprobeArgs += "json "
  If ( $containsSingleQuote ) {
    $ffprobeArgs += "`"$($File)`""
  }
  Else {
    $ffprobeArgs += "`'$($File)`'"
  }

  $getBitrateArray = Invoke-Expression -Command "$($ffprobe) $($ffprobeArgs)"
  $bitrateArray = $getBitrateArray | convertfrom-json
  [Int] $videoBitrate =  $bitrateArray.streams.bit_rate[0]
  [Int] $audioBitrate =  $bitrateArray.streams.bit_rate[0]
  [Int] $totalBitrate = $videoBitrate + $audioBitrate

  return $totalBitrate

}