#Load config file
If (Test-Path $prop.cfg_path) {
    $cfgRawString = Get-Content "$($prop.cfg_path)" | Out-String
    $cfgStringToConvert = $cfgRawString -replace '\\', '\\'
    $cfg = ConvertFrom-StringData $cfgStringToConvert

    # Create a backup of the cfg file
    Copy-Item $prop.cfg_path "$($prop.cfg_path).bk"
    Write-Output "`nCreated a backup of $($prop.cfg_path)" -Foregroundcolor Green
}
Else {
    Write-Output "Cannot find $($prop.cfgFile)."
    Start-Sleep 10
    Exit
}