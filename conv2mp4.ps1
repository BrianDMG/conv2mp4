# Note: in order to use mapped drive, you need to run "net use z: \\server\share /persistent:yes" as the user you're going to run the script as (generally Administrator)
$filelist = Get-ChildItem Z:\media\path\* -i *.mkv, *.avi, *.flv, *.mpeg -recurse

# Initialize variables  
$num = $filelist | measure
$filecount = $num.count
$time = Get-Date -format "MM/dd/yy HH:mm:ss"
Set-PSBreakpoint -Variable time -Mode Read -Action { $global:time = Get-Date -format "MM/dd/yy HH:mm:ss" }
$log = "C:\log\path\conv2mp4_out.txt"

# Begin search loop 
$i = 0;
ForEach ($file in $filelist)
{
			$i++;
			$oldfile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;
			$newfile = $file.DirectoryName + "\" + $file.BaseName + ".mp4";
			$url = "http://plexserverip:32400/library/sections/all/refresh?X-Plex-Token=plextokenhere"
			$progress = ($i / $filecount) * 100
			$progress = [Math]::Round($progress,2)
 
			Clear-Host
			Write-Output ------------------------------------------------------------------------------- | Out-File $log -Append
			Write-Output "$time Processing - $oldfile" | Out-File $log -Append
			Write-Output "$time File $i of $filecount - $progress%" | Out-File $log -Append

	
			# Begin Handbrake encode (lossy)
			# Handbrake CLI: https://trac.handbrake.fr/wiki/CLIGuide#presets
			#Start-Process "C:\Program Files\HandBrake\HandBrakeCLI.exe" -ArgumentList "-i `"$oldfile`" -t 1 --angle 1 -c 1 -o `"$newfile`" -f mp4  -O  --decomb --modulus 16 -e x264 -q 32 --vfr -a 1 -E ffaac -6 dpl2 -R Auto -B 160 -D 0 --gain 0 --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 --loose-anamorphic --x264-preset=veryfast  --x264-profile=main  --h264-level=`"4.0`"  --verbose=0" -Wait -NoNewWindow
			
			#Begin ffmpeg conversion (lossless)
			# -n skips existing file, still deletes old file. This gets rid of duplicates.
			C:\ffmpeg\bin\ffmpeg.exe -n -fflags +genpts -i "$oldfile" -vcodec copy -acodec aac "$newfile"
			Write-Output "$time ffmpeg completed" | Out-File $log -Append

			# Refresh Plex libraries
			# You can get your plex token from https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token
			# You can also easily get your token from Plex Request or PlexPy
			[System.Diagnostics.Process]::Start($url)
			(New-Object -Com Shell.Application).Open($url)
			Start-Sleep -s 10
			Stop-Process -processname chrome
			Write-Output "$time Plex library refreshed" | Out-File $log -Append
			
			# Begin file comparison between old file and new file to determine conversion success
			$file1 = Get-Item "$oldfile"
			$file2 = Get-Item "$newfile"
			
			# If new file is the same size as old file, log status and delete old file
			If ($file2.length -eq $file1.length) 
			{
				Remove-Item $oldfile -Force
				Write-Output "$time Same file size. $oldfile deleted." | Out-File $log -Append
			}
			# If new file is larger than old file, log status and delete old file
			Elseif ($file2.length -gt $file1.length) 
			{
				Remove-Item $oldfile -Force
				Write-Output "$time New file is larger. $oldfile deleted." | Out-File $log -Append
			}
			# If new file is much smaller than old file (indicating a failed conversion), log status and delete new file
			Elseif ($file2.length -lt ($file1.length * .85) )
			{
				Remove-Item $newfile -Force
				Write-Output "$time EXCEPTION: New file is over 15% smaller. $newfile deleted." | Out-File $log -Append
			}
			# If new file is smaller than old file, log status and delete old file
			Elseif ($file2.length -lt $file1.length)
			{
				Remove-Item $oldfile -Force
				Write-Output "$time New file is smaller. $oldfile deleted." | Out-File $log -Append
			}		
}		