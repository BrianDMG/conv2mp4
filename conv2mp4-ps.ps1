<#==================================================================================
conv2mp4 - https://github.com/BrianDMG/conv2mp4-ps v1.2

This Powershell script will recursively search through a defined file path and
convert all MKV, AVI, FLV, and MPEG files to MP4 using ffmpeg + audio to AAC. If it
detects a conversion failure, it will re-encode the file with Handbrake.
It then refreshes a Plex library, and upon conversion success deletes the source 
(original) file. The purpose of this script is to reduce transcodes from Plex.
=====================================================================================

ffmpeg : https://ffmpeg.org/download.html
handbrakecli : https://handbrake.fr/downloads.php

-------------------------------------------------------------------------------------
User-specific variables
-------------------------------------------------------------------------------------
$mediaPath = the path to the media you want to convert
NOTE: to use mapped drive, you must run "net use z: \\server\share /persistent:yes" as the user you're going to run the script as (generally Administrator) prior to running the script
$fileTypes = the extensions of the files you want to convert in the format "*.ex1", "*.ex2" 
$log = path you want the log file to save to. defaults to your desktop.
$plexIP = the IP address and port of your Plex server (for the purpose of refreshing its library)
$plexToken = your Plex server's token (for the purpose of refreshing its library). 
-Plex server token - See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token
--Plex server token is also easy to retrive with Couchpotato or SickRage 
$ffmpeg = path to ffmpeg.exe
$handbrake = path to HandBrakeCLI.exe #>
$mediaPath = "Z:\media"
$fileTypes = "*.mkv", "*.avi", "*.flv", "*.mpeg"
$log = "C:\Users\$env:username\Desktop\conv2mp4-ps.log"
$plexIP = 'plexserverip:32400'
$plexToken = 'yourplextoken'
$ffmpeg = "C:\ffmpeg\bin\ffmpeg.exe"
$handbrake = "C:\Program Files\HandBrake\HandBrakeCLI.exe"

<#----------------------------------------------------------------------------------
Other variables
----------------------------------------------------------------------------------#>
$mPath = Get-Item -Path $mediaPath
$fileList = Get-ChildItem "$($mPath.FullName)\*" -i $fileTypes -recurse
$num = $fileList | measure
$fileCount = $num.count
$time = {Get-Date -format "MM/dd/yy HH:mm:ss"}
	
<#----------------------------------------------------------------------------------
Begin search loop 
----------------------------------------------------------------------------------#>
$i = 0;
ForEach ($file in $fileList)
{
	$i++;
	$oldFile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;
	$newFile = $file.DirectoryName + "\" + $file.BaseName + ".mp4";
	$plexURL = "http://$plexIP/library/sections/all/refresh?X-Plex-Token=$plexToken"
	$progress = ($i / $fileCount) * 100
	$progress = [Math]::Round($progress,2)
	
	<#----------------------------------------------------------------------------------
	Do work
	----------------------------------------------------------------------------------#>
	Clear-Host
	Write-Output "------------------------------------------------------------------------------------" | Out-File $log -Append
	Write-Output "$($time.Invoke()) Processing - $oldFile" | Out-File $log -Append
	Write-Output "$($time.Invoke()) File $i of $fileCount - $progress%" | Out-File $log -Append
	
	<#----------------------------------------------------------------------------------
	ffmpeg variables
	----------------------------------------------------------------------------------#>
	$ffarg1 = "-n"
	$ffarg2 = "-fflags"
	$ffarg3 = "+genpts"
	$ffarg4 = "-i"
	$ffarg5 = "$oldFile"
	$ffarg6 = "-vcodec"
	$ffarg7 = "copy"
	$ffarg8 = "-acodec"
	$ffarg9 = "aac"
	$ffarg10 = "$newFile"
	$ffargs = @($ffarg1, $ffarg2, $ffarg3, $ffarg4, $ffarg5, $ffarg6, $ffarg7, $ffarg8, $ffarg9, $ffarg10)
	$ffcmd = &$ffmpeg $ffargs
	
	<#----------------------------------------------------------------------------------
	Begin ffmpeg conversion (lossless)
	-----------------------------------------------------------------------------------#>
	$ffcmd
	Write-Output "$($time.Invoke()) ffmpeg completed" | Out-File $log -Append

	<#----------------------------------------------------------------------------------
	Refresh Plex libraries in Chrome
	-----------------------------------------------------------------------------------#>
	[System.Diagnostics.Process]::Start($plexURL)
	(New-Object -Com Shell.Application).Open($plexURL)
	Start-Sleep -s 10
	Stop-Process -processname chrome
	Write-Output "$($time.Invoke()) Plex library refreshed" | Out-File $log -Append

	<#----------------------------------------------------------------------------------
	Begin file comparison between old file and new file to determine conversion success
	-----------------------------------------------------------------------------------#>
	# Load files for comparison
	$fileOld = Get-Item $oldFile
	$fileNew = Get-Item $newFile
			
	# If new file is the same size as old file, log status and delete old file
	If ($fileNew.length -eq $fileOld.length) 
		{
			Remove-Item $oldFile -Force
			Write-Output "$($time.Invoke()) Same file size ($($fileNew.length)MB). $oldFile deleted." | Out-File $log -Append
		}
			
	# If new file is larger than old file, log status and delete old file
	Elseif ($fileNew.length -gt $fileOld.length) 
		{
			$diffGT = [Math]::Round($fileNew.length-$fileOld.length)/1MB -as [int]
			Remove-Item $oldFile -Force
			Write-Output "$($time.Invoke()) New file is $($diffGT)MB larger. $oldFile deleted." | Out-File $log -Append
		}
			
	# If new file is much smaller than old file (indicating a failed conversion), log status, delete new file, and re-encode with HandbrakeCLI
	Elseif ($fileNew.length -lt ($fileOld.length * .75) )
		{
			$diffErr = [Math]::Round($fileNew.length-$fileOld.length)/1MB -as [int]
			Remove-Item $newFile -Force
			Write-Output "$($time.Invoke()) EXCEPTION: New file is over 25% smaller ($($diffErr)MB). $newFile deleted." | Out-File $log -Append
			Write-Output "$($time.Invoke()) FAILOVER: Re-encoding $oldFile with Handbrake." | Out-File $log -Append
				# Begin Handbrake encode (lossy)
				# Handbrake CLI: https://trac.handbrake.fr/wiki/CLIGuide#presets
				
				<#----------------------------------------------------------------------------------
				HandbrakeCLI variables
				----------------------------------------------------------------------------------#>
				$hbarg1 = "-i"
				$hbarg2 = "$oldFile"
				$hbarg3 = "-o"
				$hbarg4 = "$newFile"
				$hbarg5 = "-f"
				$hbarg6 = "mp4"
				$hbarg7 = "--loose-anamorphic"
				$hbarg8 = "--modulus"
				$hbarg9 = "2"
				$hbarg10 = "-e"
				$hbarg11 = "x264"
				$hbarg12 = "-q"
				$hbarg13 = "19"
				$hbarg14 = "--cfr"
				$hbarg15 = "-a"
				$hbarg16 = "1"
				$hbarg17 = "-E"
				$hbarg18 = "faac"
				$hbarg19 = "-6"
				$hbarg20 = "dp12"
				$hbarg21 = "-R"
				$hbarg22 = "Auto"
				$hbarg23 = "-B"
				$hbarg24 = "320"
				$hbarg25 = "-D"
				$hbarg26 = "0"
				$hbarg27 = "--gain"
				$hbarg28 = "0"
				$hbarg29 = "--audio-copy-mask"
				$hbarg30 = "none"
				$hbarg31 = "--audio-fallback"
				$hbarg32 = "ffac3"
				$hbarg33 = "-x"
				$hbarg34 = "ref=16:bframes=16:b-adapt=2:direct=auto:me=tesa:merange=24:subq=11:rc-lookahead=60:analyse=all:trellis=2:no-fast-pskip=1"
				$hbarg35 = "--verbose=1"
				$hbargs = @($hbarg1, $hbarg2, $hbarg3, $hbarg4, $hbarg5, $hbarg6, $hbarg7, $hbarg8, $hbarg9, $hbarg10, $hbarg11, $hbarg12, $hbarg13, $hbarg14, $hbarg15, $hbarg16, $hbarg17, $hbarg18, $hbarg19, $hbarg20, $hbarg21, $hbarg22, $hbarg23, $hbarg24, $hbarg25, $hbarg26, $hbarg27, $hbarg28, $hbarg29, $hbarg30, $hbarg31, $hbarg32, $hbarg33, $hbarg34, $hbarg35)
				$hbcmd = &$handbrake $hbargs
	
					$hbcmd
					Write-Output "$($time.Invoke()) Handbrake finished." | Out-File $log -Append
					Write-Output "$($time.Invoke()) $oldFile deleted." | Out-File $log -Append
		}
			
	# If new file is smaller than old file, log status and delete old file
	Elseif ($fileNew.length -lt $fileOld.length)
		{
			$diffLT = [Math]::Round($fileOld.length-$fileNew.length)/1MB -as [int]
			Remove-Item $oldFile -Force
			Write-Output "$($time.Invoke()) New file is $($diffLT)MB smaller. $oldFile deleted." | Out-File $log -Append
		}		
}		