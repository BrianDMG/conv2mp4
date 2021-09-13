# If new and old files are the same size
Function Compare-IfSame {

  Try {
    Remove-Item "$($sourceFile)" -Force -ErrorAction Stop
    Add-Log "$($time.Invoke()) Same file size."
    Add-Log "$($time.Invoke()) $($sourceFile) deleted."
    Add-Log "$($time.Invoke()) $($targetFileRenamed) created."
  }
  Catch
  {
    Add-Log "$($time.Invoke()) ERROR: $($sourceFile) could not be deleted. Full error below."
    Add-Log $_
  }
}