# conv2mp4-ps
This Powershell script will recursively search through a defined file path and convert all MKV, AVI, FLV, and MPEG files to MP4 using ffmpeg (and converts audio channels to AAC). It then refreshes a Plex library, and upon conversion success deletes the source (original) file. The purpose of this script is to reduce the number of transcodes performed by a Plex server.
