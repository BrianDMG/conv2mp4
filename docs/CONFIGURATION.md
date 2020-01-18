# Configuration

## **User-defined variables (*files\cfg\config*)**
There are several user-defined variables you will need to edit using a text editor like [Notepad++](https://notepad-plus-plus.org/download/) or [VS Code](https://code.visualstudio.com/download).

---

### File paths
All files paths must be specified in the following formats, and are case-sensitive:
- `C:\path\to\files` for local files and folders
- `\\path\to\files` for network shares
<br>
- **mediaPath**: the path to the media you want to convert
    - *NOTE: If running manually and using a mapped drive, you must run `net use z: \\server\share /persistent:yes` as the user you're going to run the script as (generally Administrator) prior to running the script.*
- **ffmpegBinDir**: path to ffmpeg bin folder. This is the directory containing ffmpeg.exe and ffprobe.exe. Defaults to `C:\ffmpeg\bin` on Windows.
- **handbrakeDir**: path to the directory containing HandBrakeCLI.exe. Defaults to `C:\Program Files\HandBrake` on Windows.
- **useOutPath**: `false` will use mediaPath as the output folder. `true` will output converted files to `outPath`.
- **outPath**: If `useOutPath=true`, converted files will be written to this directory.

### Conversion settings
- **fileTypes**: the extensions of the files you want to convert in the format `*.ext1, *.ext2`. Types specified in `files\cfg\config.template` are defualts that should not be removed (`*.mkv` and `*.mp4`)
- **setTitle**: true
- **failOverThresh** =.60

### Audio encoding options
- **force2chCopy**: false

### Subtitle options
- **keepSubs**: `false` will discard subtitles from converted files. `true` will keep existing subtitle tracks.

### Log settings
- **appendLog**: `false` will clear the log at the beginning of every session, `true` will append new session log to old session log.
- **useIgnore**: `true` will use the ignore list feature to reduce script execution times. `false` will disable the ignore list and scan every file in mediaPath for every execution.

### Plex configuration
- **usePlex**: if set to `true`, Plex settings will be used. Set to `false` if Plex feature is not needed.
- **plexIP**: the IP address and port (generally `32400`) of your Plex server (*for the purpose of refreshing its libraries*).
- **plexToken**: your Plex server's token (*for the purpose of refreshing its libraries*).
    - NOTE: *Plex server token - See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token. Plex server token is also easy to retrieve with Tautulli or Ombi*

### Garbage collection
- **collectGarbage**: `true` enables garbage collection. `false` disables garbage collection.
- **garbage**: the extensions of the files you want garbage collection to delete in the format `"*.ext1", "*.ext2"`.