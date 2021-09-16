Function Get-AudioStreams {

  $ffprobe = Join-Path $cfg.paths.ffmpeg 'ffprobe'

  $ffprobeArgs += "-v "
  $ffprobeArgs += "error "
  If ( $targetFile.Contains("'") ) {
    $ffprobeArgs += "`"$($targetFile)`" " #Output file
  }
  Else {
    $ffprobeArgs += "`'$($targetFile)`' " #Output file
  }
  $ffprobeArgs += "-show_entries "
  $ffprobeArgs += "stream=channels "
  $ffprobeArgs += "-select_streams "
  $ffprobeArgs += "a "
  $ffprobeArgs += "-of "
  $ffprobeArgs += "compact=p=0:nk=1"

  [ int[] ] $audioStreamArray = Invoke-Expression -Command "$($ffprobe) $($ffprobeArgs)"

  #If last channel is not stereo, create one
  If ($audioStreamArray[$audioStreamArray.Length-1] -gt 2 ) {
    return $True
  }
  #If not, skip stream clone
  Else {
    return $False
  }

}