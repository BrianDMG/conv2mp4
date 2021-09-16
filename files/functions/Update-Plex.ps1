#Refresh Plex libraries
Function Update-Plex {

    $plexURL = "http://$($cfg.plex.ip)/library/sections/all/refresh?X-Plex-Token=$($cfg.plex.token)"

    Invoke-WebRequest $plexURL -UseBasicParsing
    Add-Log "$($time.Invoke()) Plex libraries refreshed"

}