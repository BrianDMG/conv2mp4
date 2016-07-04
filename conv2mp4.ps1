# ----------------------------------------------------------------------------------
# conv2mp4 - https://github.com/BrianDMG/conv2mp4-ps v1.1
#
# This Powershell script will recursively search through a defined file path and
# convert all MKV, AVI, FLV, and MPEG files to MP4 using ffmpeg + audio to AAC. 
# It then refreshes a Plex library, and upon conversion success deletes the source 
# (original) file. The purpose of this script is to reduce transcodes from Plex.
# ----------------------------------------------------------------------------------


# ----------------------------------------------------------------------------------
# User-specific variables
# ----------------------------------------------------------------------------------

# Media path
# NOTE: to use mapped drive, you must run "net use z: \\server\share /persistent:yes" as the user you're going to run the script as (generally Administrator) prior to running the script
$mediapath = Get-Item -Path "Z:\media\"
# File types the script will convert or encode
$filetypes = "*.mkv", "*.avi", "*.flv", "*.mpeg"
# Log path
$log = "C:\Users\$env:username\Desktop\conv2mp4_out.log"
# Plex server IP address and port
$plexip = 'plexip:32400'
# Plex server token - See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token
# Plex server token is also easy to retrive with Couchpotato or SickRage
$plextoken = 'plextoken'

# Other variables
$filelist = Get-ChildItem -Path "$($mediapath.FullName)\*" -File -Include $filetypes -recurse
$num = $filelist | measure
$filecount = $num.count
$time = Get-Date -format "MM/dd/yy HH:mm:ss"
Set-PSBreakpoint -Variable time -Mode Read -Action { $global:time = Get-Date -format "MM/dd/yy HH:mm:ss" }

# Begin search loop 
$i = 0;
ForEach ($file in $filelist)
{
	$i++;
	$oldfile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;
	$newfile = $file.DirectoryName + "\" + $file.BaseName + ".mp4";
	$plexurl = "http://$plexip/library/sections/all/refresh?X-Plex-Token=$plextoken"
	$progress = ($i / $filecount) * 100
	$progress = [Math]::Round($progress,2)
 
		Clear-Host
		Write-Output ------------------------------------------------------------------------------- | Out-File $log -Append
		Write-Output "$time Processing - $oldfile" | Out-File $log -Append
		Write-Output "$time File $i of $filecount - $progress%" | Out-File $log -Append

			# Begin ffmpeg conversion (lossless)
			# -n skips existing file, still deletes old file. This favors existing files and gets rid of duplicates.
			C:\ffmpeg\bin\ffmpeg.exe -n -fflags +genpts -i "$oldfile" -vcodec copy -acodec aac "$newfile"
			Write-Output "$time ffmpeg completed" | Out-File $log -Append

			# Refresh Plex libraries in Chrome
			[System.Diagnostics.Process]::Start($plexurl)
			(New-Object -Com Shell.Application).Open($plexurl)
			Start-Sleep -s 10
			Stop-Process -processname chrome
			Write-Output "$time Plex library refreshed" | Out-File $log -Append
			
			# Begin file comparison between old file and new file to determine conversion success
			# If new file is the same size as old file, log status and delete old file
			If ($newfile.length -eq $oldfile.length) 
			{
				Remove-Item $oldfile -Force
				Write-Output "$time Same file size. $oldfile deleted." | Out-File $log -Append
			}
			# If new file is larger than old file, log status and delete old file
			Elseif ($newfile.length -gt $oldfile.length) 
			{
				Remove-Item $oldfile -Force
				Write-Output "$time New file is larger. $oldfile deleted." | Out-File $log -Append
			}
			# If new file is much smaller than old file (indicating a failed conversion), log status and delete new file
			Elseif ($newfile.length -lt ($oldfile.length * .85) )
			{
				Remove-Item $newfile -Force
				Write-Output "$time EXCEPTION: New file is over 15% smaller. $newfile deleted." | Out-File $log -Append
				#Write-Output "$time Re-encoding $oldfile with Handbrake." | Out-File $log -Append
				# Begin Handbrake encode (lossy)
				# Handbrake CLI: https://trac.handbrake.fr/wiki/CLIGuide#presets
				#Start-Process "C:\Program Files\HandBrake\HandBrakeCLI.exe" -ArgumentList "-i `"$oldfile`" -t 1 --angle 1 -c 1 -o `"$newfile`" -f mp4  -O  --decomb --modulus 16 -e x264 -q 32 --vfr -a 1 -E ffaac -6 dpl2 -R Auto -B 160 -D 0 --gain 0 --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 --loose-anamorphic --x264-preset=veryfast  --x264-profile=main  --h264-level=`"4.0`"  --verbose=0" -Wait -NoNewWindow
				#Write-Output "$time $oldfile successfully re-encoded and deleted." | Out-File $log -Append
			}
			# If new file is smaller than old file, log status and delete old file
			Elseif ($newfile.length -lt $oldfile.length)
			{
				Remove-Item $oldfile -Force
				Write-Output "$time New file is smaller. $oldfile deleted." | Out-File $log -Append
			}		
}		