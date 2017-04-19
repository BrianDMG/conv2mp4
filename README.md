# conv2mp4-ps
Powershell script that recursively searches through a user-defined file path and convert all videos of user-specified  file types to MP4 with H264 video and AAC audio as needed using ffmpeg. If a conversion failure is detected, the script re-encodes the file with HandbrakeCLI. Upon successful encoding, Plex libraries are refreshed and source file is deleted.  The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server and increase video compatibility across platforms.<br><br>
Python version can be found here: <a href="https://github.com/BrianDMG/conv2mp4-py">conv2mp4-py</a><br><br>
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
<b>$handbrakeDir</b> = path to Handbrake directory <i>(no trailing "\")</i>. This is the directory containing HandBrakeCLI.exe<br>
<b>$script:garbage</b> = the extensions of the files you want to delete in the format "*.ex1", "*.ex2"<br>
<b>$appendLog</b> = $False will clear log at the beginning of every session, $True will append new session log to old session log

<b>Scheduled task example</b><br>
To fully automate this script on a Windows system, you will need to set it as a scheduled task. The following is a brief example of how to do that.
<ol><li>Open task scheduler and choose <b>"Create task"</b></li>
<li>On the <b>General</b> tab:
<ul><li>Give the task a name. This can be whatever you like, but should be something descriptive.</li>
<li>(<i>Optional</i>) Write a short description of the task.</li>
<li>Click the <b>Change User or group</b> button, and ensure that both the computer name and user name show up in the format of "Computer\User".</li>
<li>Click the <b>Run whether user is logged in or not</b> radio button</li>
<li>Check the <b>Run with highest privileges</b> button</li></ul>
<img src="http://teague.io/wp-content/uploads/2017/04/1.png"><br></li>
<li>Under the <b>Triggers</b> tab:
<ul><li>Change "Begin the task" dropdown to <b>On a schedule</b></li>
<li>Change the scheduling settings to your liking. Choose a time when your server's usage is typically minimal, and allows time for the script to run and complete before usage picks back up.</li>
<li>Ensure the <b>Enabled</b> checkbox is selected</li></ul>
<img src="http://teague.io/wp-content/uploads/2017/04/2.png"></li>
<li>On the <b>Actions</b> tab:
<ul><li>Click the <b>New action</b> button.</li>
<li>Change the <b>Action</b> dropdown to <b>Start a program</b>.</li>
<li>Under <b>Program/script</b>, type <b>Powershell.exe</b></li>
<li>In the <b>Add arguments</b> field, enter <b>-ExecutionPolicy Bypass -File c:\path\to\script\conv2mp4-ps.ps1</b></li></ul>
<img src="http://teague.io/wp-content/uploads/2017/04/3.png"></li>
<li>(<i>Optional</i>) Tailor settings under the <b>Conditions</b> and <b>Settings</b> tabs to your liking</li></ol>
The script will now run automatically to your specifications.
