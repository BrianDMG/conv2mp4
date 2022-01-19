Function Compare-Duplicates {

  Param(
    [String]$File1, #Should be targetFile
    [String]$File2 #Should be sourceFile
  )

  Add-Log "$($time.Invoke()) Found duplicate, comparing bitrates..."

  $file1TotalBitrate = Get-FileBitrate -File $File1
  $file2TotalBitrate = Get-FileBitrate -File $File2

  Add-Log "$($File1) Total bitrate: $($file1TotalBitrate)"
  Add-Log "$($File2) Total bitrate: $($file2TotalBitrate)"

  If ( ($file1TotalBitrate -gt $file2TotalBitrate) -OR ($file2TotalBitrate -eq $file2TotalBitrate)  -OR ($file1TotalBitrate -eq 'N/A') -OR ($file2TotalBitrate -eq 'N/A') ) {
    $higherBitrate = $File1
    $lowerBitrate = $File2
  }
  Else {
    $higherBitrate = $File2
    $lowerBitrate = $File1
  }

  Remove-Item "$($lowerBitrate)" -Force
  Add-Log "$($time.Invoke()) Deleted lower bitrate: $($lowerBitrate)."

  $duplicatesDeleted += @($lowerBitrate)

}