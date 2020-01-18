# If new and old files are the same size
Function IfSame {
    Try {
        Remove-Item $oldFile -Force -ErrorAction Stop
        Log "$($time.Invoke()) Same file size."
        Log "$($time.Invoke()) $oldFile deleted."
    }
    Catch
    {
        Log "$($time.Invoke()) ERROR: $oldFile could not be deleted. Full error below."
        Log $_
    }
}