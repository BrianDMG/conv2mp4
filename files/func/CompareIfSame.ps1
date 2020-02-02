# If new and old files are the same size
Function CompareIfSame {
    Try {
        Remove-Item $sourceFile -Force -ErrorAction Stop
        Log "$($time.Invoke()) Same file size."
        Log "$($time.Invoke()) $sourceFile deleted."
        Log "$($time.Invoke()) $targetFileRenamed created."
    }
    Catch
    {
        Log "$($time.Invoke()) ERROR: $sourceFile could not be deleted. Full error below."
        Log $_
    }
}