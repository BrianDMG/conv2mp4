# Configuration

## **User-defined variables (*files\cfg\config*)**
There are several user-defined variables you will need to edit using a text editor like [Notepad++](https://notepad-plus-plus.org/download/) or [VS Code](https://code.visualstudio.com/download).

---

### File paths
All files paths must be specified in the following formats, and are case-sensitive:
- `C:\path\to\files` for local files and folders
- `\\path\to\files` for network shares


- **media_path**: the path to the media you want to convert
    - *NOTE: If running manually and using a mapped drive, you must run `net use z: \\server\share /persistent:yes` as the user you're going to run the script as (generally Administrator) prior to running the script.*
- **fmmpeg_bin_dir**: path to ffmpeg bin folder. This is the directory containing ffmpeg.exe and ffprobe.exe. Defaults to `C:\ffmpeg\bin` on Windows.
- **handbrakecli_bin_dir**: path to the directory containing HandBrakeCLI.exe. Defaults to `C:\Program Files\HandBrake` on Windows.
- **use_out_path**: `false` will use media_path as the output folder. `true` will output converted files to `out_path`.
- **out_path**: If `use_out_path=true`, converted files will be written to this directory.

### Conversion settings
- **include_file_types**: the extensions of the files you want to convert in the format `*.ext1, *.ext2`. Types specified in `files\cfg\config.template` are defaults that should not be removed (`*.mkv`)
- **use_set_metadata_title**: true
- **failover_threshold** =.60

### Audio encoding options
- **force_stereo_clone**: false

### Subtitle options
- **keep_subtitles**: `false` will discard subtitles from converted files. `true` will keep existing subtitle tracks.

### Log settings
- **append_log**: `false` will clear the log at the beginning of every session, `true` will append new session log to old session log.
- **use_ignore_list**: `true` will use the ignore list feature to reduce script execution times. `false` will disable the ignore list and scan every file in media_path for every execution.

### Plex configuration
- **use_plex**: if set to `true`, Plex settings will be used. Set to `false` if Plex feature is not needed.
- **plex_ip**: the IP address and port (generally `32400`) of your Plex server (*for the purpose of refreshing its libraries*).
- **plex_token**: your Plex server's token (*for the purpose of refreshing its libraries*).
    - NOTE: *Plex server token - See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token. Plex server token is also easy to retrieve with Tautulli or Ombi*

### Garbage collection
- **collect_garbage**: `true` enables garbage collection. `false` disables garbage collection.
- **garbage_include_file_types**: the extensions of the files you want garbage collection to delete in the format `"*.ext1", "*.ext2"`.