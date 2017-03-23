# conv2mp4-ps
Powershell script that recursively searches through a user-defined file path and convert all videos of user-specified  file types to MP4 with H264 video and AAC audio as needed using ffmpeg. If a conversion failure is detected, the script re-encodes the file with HandbrakeCLI. Upon successful encoding, Plex libraries are refreshed and source file is deleted.  The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server and increase video compatibility across platforms.<br><br>
<b><u>Dependencies</u></b><br>
This script requires ffmpeg (ffmpeg.exe, ffprobe.exe) and Handbrake (HandbrakeCLI.exe) to be installed. You can download them from here:<br>
<a href="https://ffmpeg.org/download.html">ffmpeg</a><br>
<a href="https://handbrake.fr/downloads.php">Handbrake</a><br><br>
<b>Usage</b><br>
To use this script on a Windows computer, simply right click the file and choose "Run with Powershell". Additionally, you can run the script as a scheduled task for full automation.<br><br>
<b>User-defined variables</b><br>
There are several user-defined variables you will need to edit using notepad or a program like <a href="https://notepad-plus-plus.org/download/v6.9.2.html">Notepad++</a>.<br><br>
<b>$mediaPath</b> = the path to the media you want to convert <i>(no trailing "\")</i><br>
<u>NOTE:</u> <i>For network shares, use UNC path if you plan on running this script as a scheduled task. If running manually and using a mapped drive, you must run "net use z: \\server\share /persistent:yes" as the user you're going to run the script as (generally Administrator) prior to running the script.</i><br>
<b>$fileTypes</b> = the extensions of the files you want to convert in the format "*.ex1", "*.ex2"<br> 
<b>$logPath</b> = path you want the log file to save to. defaults to your desktop. <i>(no trailing "\")</i><br>
<b>$logName</b> = the filename of the log file<br>
<b>$plexIP</b> = the IP address and port of your Plex server (for the purpose of refreshing its libraries)<br>
<b>$plexToken</b> = your Plex server's token (for the purpose of refreshing its libraries).<br>
<u>NOTE:</u> <i>Plex server token - See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token. Plex server token is also easy to retrieve with PlexPy, Ombi, Couchpotato, or SickRage.</i><br>
<b>$ffmpegBinDir</b> = path to ffmpeg bin folder <i>(no trailing "\")</i>. This is the directory containing ffmpeg.exe and ffprobe.exe<br> 
<b>$handbrake</b> = path to Handbrake directory <i>(no trailing "\")</i>. This is the directory containing HandBrakeCLI.exe<br>
<b>$script:garbage</b> = the extensions of the files you want to delete in the format "*.ex1", "*.ex2"
