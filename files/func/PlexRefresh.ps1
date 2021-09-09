#Refresh Plex libraries
Function PlexRefresh {
    $plexURL = "http://$($cfg.plex.ip)/library/sections/all/refresh?X-Plex-Token=$($cfg.plex.token)"
    Invoke-WebRequest $plexURL -UseBasicParsing
    Log "$($time.Invoke()) Plex libraries refreshed"
}