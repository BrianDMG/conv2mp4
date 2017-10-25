# conv2mp4-ps
Powershell script that recursively searches through a user-defined file path (*or paths*) and convert all videos of user-specified file types to **MP4** with **H264** video and **AAC** audio as needed using ffmpeg. If a conversion failure is detected, the script re-encodes the file with HandbrakeCLI. Upon successful encoding, Plex libraries are (optionally) refreshed and source file is deleted. The purpose of this script is to reduce the amount of transcoding CPU load on a Plex, Emby, or Kodi server and increase video compatibility across platforms.
Python version can be found here: <a href="https://github.com/BrianDMG/conv2mp4-py">conv2mp4-py</a>

**Want to [contribute](docs/CONTRIBUTING.md)? [Pull requests](docs/PULL_REQUEST_TEMPLATE.md) welcome!**

### **Dependencies**
This script requires ffmpeg (*ffmpeg.exe, ffprobe.exe*) and Handbrake (*HandbrakeCLI.exe*) to be installed. You can download them from here:
* [ffmpeg](https://ffmpeg.org/download.html)
* [Handbrake](https://handbrake.fr/downloads.php)

### **[Usage](docs/USAGE.md)**

### **[Scheduled task example](docs/SCHEDULED_TASK.md)**