## **Usage**
* **conv2mp4-ps.ps1**: the executable script.
To use this script on a Windows computer, simply right click the file (**conv2mp4-ps.ps1**) and choose "*Run with Powershell*". Additionally, you can run the script as a scheduled task for full automation.</li>
* **cfg_conv2mp4-ps.ps1**: configuration file, contains user-defined variables.
	- *NOTE: If you're upgrading from v2.2 or lower, you may copy your old settings over, but take care not to delete the variables that have been added since the last update. Using a diff/merge tool like [WinMerge](http://winmerge.org/downloads/) is recommended*

#### **User-defined variables (*cfg_conv2mp4.ps1*)**
* There are several user-defined variables you will need to edit using a text editor like[Notepad++](https://notepad-plus-plus.org/download/).

**$mediaPath** = the path to the media you want to convert *(no trailing "\")*
	- *NOTE: For network shares, use UNC path if you plan on running this script as a scheduled task. If running manually and using a mapped drive, you must run ```net use z: \\server\share /persistent:yes``` as the user you're going to run the script as (generally Administrator) prior to running the script.*
**$fileTypes** = the extensions of the files you want to convert in the format ```"*.ex1", "*.ex2"``` 
**$logPath** = the path you want the log file to save to. Defaults to your desktop. *(no trailing "\")*
**$logName** = the filename of the log file
**$usePlex** = if set to ```$True```, Plex settings will be used. Set to ```$False``` if Plex feature is not needed
**$plexIP** = the IP address and port (generally ```32400```) of your Plex server (for the purpose of refreshing its libraries)
**$plexToken** = your Plex server's token (for the purpose of refreshing its libraries).
	- NOTE: *Plex server token - See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token. Plex server token is also easy to retrieve with PlexPy, Ombi, Couchpotato, or SickRage*
**$ffmpegBinDir** = path to ffmpeg bin folder *(no trailing "\")*. This is the directory containing ffmpeg.exe and ffprobe.exe 
**$handbrakeDir** = path to Handbrake directory *(no trailing "\")*. This is the directory containing HandBrakeCLI.exe
**collectGarbage** = ```$True``` enables garbage collection. ```$False``` disables garbage collection.
**$script:garbage** = the extensions of the files you want garbage collection to delete in the format ```"*.ex1", "*.ex2"```
**$appendLog** = ```$False``` will clear the log at the beginning of every session, ```$True``` will append new session log to old session log.
**$keepSubs** = ```$False``` will discard subtitles from converted files. ```$True``` will keep subtitles.
**$useOutPath** = ```$False``` will use $mediaPath as the output folder. ```$True``` will output converted files to ```$outPath```
**$outPath** = If ```$useOutPath``` = ```$True```, converted files will be written to this directory (no trailing "\")