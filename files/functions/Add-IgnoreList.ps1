Function Add-IgnoreList {

  Param (
    [String]$ignoreString
  )

  Write-Output $ignoreString | Tee-Object -filepath $prop.paths.files.ignore -Append

}