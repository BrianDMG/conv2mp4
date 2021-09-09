Function AddToIgnoreList
{
    Param ([string]$ignoreString)
    Write-Output $ignoreString | Tee-Object -filepath $prop.paths.files.ignore -Append
}