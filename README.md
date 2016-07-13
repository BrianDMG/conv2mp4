# conv2mp4-ps
Powershell script that recursively searches through a defined file path and converts MKV, AVI, FLV, and MPEG files to MP4 using ffmpeg (with AAC audio). It then refreshes a Plex library, and deletes the source file upon success. Fails over to Handbrake encode if conversion failure is detected. The purpose of this script is to reduce the number of transcodes performed by a Plex server.<br><br>
<b>Dependencies</b><br>
This script requires ffmpeg and Handbrake to be installed on your computer. You can download them from here:<br>
<a href="https://ffmpeg.org/download.html">ffmpeg</a>
<a href="https://handbrake.fr/downloads.php">Handbrake</a><br><br>
To use this script on a Windows computer, simply right click the file and choose "Run with Powershell".<br><br>
<b>User-defined variables</b><br>
There are several user-defined variables you will need to edit using notepad or a program like <a href="https://notepad-plus-plus.org/download/v6.9.2.html">Notepad++</a>.<br><br>
<b>$mediaPath</b> = the path to the media you want to convert. You can also use a UNC path here.<br>
<br><i>NOTE: to use a mapped drive, you must run net use z: \\server\share /persistent:yes as the user you're going to run the script as (generally Administrator) prior to running the script.</i><br>
<b>$fileTypes</b> = the extensions of the files you want to convert in the format ".ex1", ".ex2".<br>
<b>$log</b> = path and filename you want the log file to save to. Defaults to your desktop.<br>
<b>$plexIP</b> = the IP address and port of your Plex server (for the purpose of refreshing its library)<br>
<b>$plexToken</b> = your Plex server's token (for the purpose of refreshing its library).<br>
<i>NOTE: See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token for instructions on retrieving your Plex server's token. Your Plex server's token is also easy to retrieve with Couchpotato or SickRage.</i><br>
<b>$ffmpeg</b> = path to ffmpeg.exe<br>
<b>$handbrake</b> = path to HandBrakeCLI.exe
