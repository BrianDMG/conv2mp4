#Refresh Plex libraries
Function PlexRefresh {
    $plexURL = "http://$($cfg.plexIP)/library/sections/all/refresh?X-Plex-Token=$($cfg.plexToken)"
    Invoke-WebRequest $plexURL -UseBasicParsing
    Log "$($time.Invoke()) Plex libraries refreshed"
}