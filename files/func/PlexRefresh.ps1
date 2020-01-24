#Refresh Plex libraries
Function PlexRefresh {
    $plexURL = "http://$($cfg.plex_ip)/library/sections/all/refresh?X-Plex-Token=$($cfg.plex_token)"
    Invoke-WebRequest $plexURL -UseBasicParsing
    Log "$($time.Invoke()) Plex libraries refreshed"
}