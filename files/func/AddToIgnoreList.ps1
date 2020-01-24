Function AddToIgnoreList
{
    Param ([string]$ignoreString)
    Write-Output $ignoreString | Tee-Object -filepath $prop.ignore_path -Append
}