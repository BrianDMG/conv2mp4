do{
  pwsh /c /app/conv2mp4-ps.ps1
  Write-Output "Sleeping 12 hours..."
  start-sleep -Hours 12
}until($infinity)