#Load properties file
$propFile = Convert-Path "files\prop\properties"
$propRawString = Get-Content "$propFile" | Out-String
$propStringToConvert = $propRawString -replace '\\', '\\'
$prop = ConvertFrom-StringData $propStringToConvert
Remove-Variable -Name propFile, propRawString, propSTringToConvert

#Load configuration
$cfgRawString = Get-Content "$($prop.cfg_path)" | Out-String
$cfgStringToConvert = $cfgRawString -replace '\\', '\\'
$cfg = ConvertFrom-StringData $cfgStringToConvert
Remove-Variable -Name cfgRawString, cfgStringToConvert

Function Sleep-Progress($seconds) {
  $s = 0;
  Do {
    $p = [math]::Round(100 - (($seconds - $s) / $seconds * 100));
    Write-Progress -Activity "Waiting: script will excute when complete..." -Status "$p% Complete:" -SecondsRemaining ($seconds - $s) -PercentComplete $p;
    [System.Threading.Thread]::Sleep(500)
    $s++;
  }
  While($s -lt $seconds);
}

Do {
  pwsh /c /app/conv2mp4-ps.ps1
  Write-Output "Sleeping $($cfg.run_interval) seconds..."
  Sleep-Progress $($cfg.run_interval)
}
Until ($infinity)
