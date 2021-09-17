Function Write-Version {

  Add-Log "conv2mp4 - platform: $($prop.platform) ver: $($prop.version) rev: $($env:REVISION)`n$($prop.urls.gitlab) | $($prop.urls.dockerhub)"

  If ($cfg.notifications.check_for_updates) {
    Get-LatestVersion -CurrentVersion $prop.version
  }

}