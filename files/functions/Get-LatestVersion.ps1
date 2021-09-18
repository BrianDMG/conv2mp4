Function Get-LatestVersion {

  Param(
    [String]$CurrentVersion
  )

  Try {
    #Set up API request
    $request = Invoke-WebRequest -Uri "$($prop.urls.dockerhub_tag_api)"
    $requestObj = $request.Content | ConvertFrom-Json

    $dockerHubLatestTag = $requestObj.results[1].name

    [Int] $currentTagInt = $CurrentVersion.replace('.','')
    [Int] $dockerHubLatestTagInt = $requestObj.results[1].name.replace('v','').replace('.','')

    $dockerHubLatestTagSha = $requestObj.results[1].images[0].digest.replace(':','-')
    $dockerHubImageURL =  $prop.urls.dockerhub_tag_url_a + $dockerHubLatestTag + $prop.urls.dockerhub_tag_url_b + $dockerHubLatestTagSha + $prop.urls.dockerhub_tag_url_c

    If ( $dockerHubLatestTagInt -gt $currentTagInt ) {
      Add-Log "`n🔔 Update available: $($dockerHubLatestTag) @ $($dockerHubImageURL)"
      return $True
    }

  }
  Catch {
    Add-Log "Unable to check for updates."
    Add-Log "ERROR: $($_)"
  }

}