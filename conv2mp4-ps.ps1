<#==================================================================================
conv2mp4 - https://github.com/BrianDMG/conv2mp4-ps v1.4

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
NOTE: to use mapped drive, you must run "net use z: \\server\share /persistent:yes" as the user you're going to run the script as (generally Administrator) prior to running the script. You can also use a UNC path here.
$fileTypes = the extensions of the files you want to convert in the format "*.ex1", "*.ex2" 
$logPath = path you want the log file to save to. defaults to your desktop.
$plexIP = the IP address and port of your Plex server (for the purpose of refreshing its library)
$plexToken = your Plex server's token (for the purpose of refreshing its library). 
-Plex server token - See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token
--Plex server token is also easy to retrive with Couchpotato or SickRage 
$ffmpeg = path to ffmpeg.exe
$handbrake = path to HandBrakeCLI.exe #>
$mediaPath = "Z:\media"
$fileTypes = "*.mkv", "*.avi", "*.flv", "*.mpeg", "*.ts"
$logPath = "C:\Users\$env:username\Desktop\conv2mp4-ps.log"
$plexIP = 'plexip:32400'
$plexToken = 'plextoken'
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
	Begin logging output
	----------------------------------------------------------------------------------#>
	Clear-Host
	Write-Output "------------------------------------------------------------------------------------" | Out-File $logPath -Append
	Write-Output "$($time.Invoke()) Processing - $oldFile" | Out-File $logPath -Append
	Write-Output "$($time.Invoke()) File $i of $fileCount - $progress%" | Out-File $logPath -Append
	
		<#----------------------------------------------------------------------------------
		ffmpeg arguments
		----------------------------------------------------------------------------------#>
		$ffArg1 = "-n"
		$ffArg2 = "-fflags"
		$ffArg3 = "+genpts"
		$ffArg4 = "-i"
		$ffArg5 = "$oldFile"
		$ffArg6 = "-map"
		$ffArg7 = "0"
		$ffArg8 = "-c:v"
		$ffArg9 = "copy"
		$ffArg10 = "-c:a"
		$ffArg11 = "aac"
		$ffArg12 = "-c:s"
		$ffArg13 = "mov_text"
		$ffArg14 = "$newFile"
		$ffArgs = @($ffArg1, $ffArg2, $ffArg3, $ffArg4, $ffArg5, $ffArg6, $ffArg7, $ffArg8, $ffArg9, $ffArg10, $ffArg11, $ffArg12, $ffArg13, $ffArg14)
		$ffCMD = &$ffmpeg $ffArgs
		
		<#----------------------------------------------------------------------------------
		Begin ffmpeg conversion (lossless)
		-----------------------------------------------------------------------------------#>
		$ffCMD
		Write-Output "$($time.Invoke()) ffmpeg completed" | Out-File $logPath -Append

		<#----------------------------------------------------------------------------------
		Refresh Plex libraries in Chrome
		-----------------------------------------------------------------------------------#>
		Invoke-WebRequest $plexURL 
		Write-Output "$($time.Invoke()) Plex library refreshed" | Out-File $logPath -Append
				
		<#----------------------------------------------------------------------------------
		Begin file comparison between old file and new file to determine conversion success
		-----------------------------------------------------------------------------------#>
		# Load files for comparison
		$fileOld = Get-Item $oldFile
		$fileNew = Get-Item $newFile
		$conDelOld = Test-Path $oldFile		
		$conDelNew = Test-Path $newFile
			
		# If new file is the same size as old file, log status and delete old file
		If ($fileNew.length -eq $fileOld.length) 
		{
			Remove-Item $oldFile -Force
		
			# Test to see if old file was deleted. If not, tries again.
			If ($confDelOld -eq $False)
			{
				Write-Output "$($time.Invoke()) Same file size. $oldFile deleted." | Out-File $logPath -Append
			}
			Else 
			{
				Remove-Item $oldFile -Force
				Write-Output "$($time.Invoke()) Same file size. $oldFile deleted." | Out-File $logPath -Append
			}
		}
					
		# If new file is larger than old file, log status and delete old file
		Elseif ($fileNew.length -gt $fileOld.length) 
		{
			$diffGT = [Math]::Round($fileNew.length-$fileOld.length)/1MB -as [int]
		
			Remove-Item $oldFile -Force
					
				If ($confDelOld -eq $False)
				{
					Write-Output "$($time.Invoke()) New file is $($diffGT)MB larger. $oldFile deleted." | Out-File $logPath -Append
				}
				Else 
				{
					Remove-Item $oldFile -Force
					Write-Output "$($time.Invoke()) New file is $($diffGT)MB larger. $oldFile deleted." | Out-File $logPath -Append
				}
		}
					
		# If new file is much smaller than old file (indicating a failed conversion), log status, delete new file, and re-encode with HandbrakeCLI
		Elseif ($fileNew.length -lt ($fileOld.length * .75) )
		{
			$diffErr = [Math]::Round($fileNew.length-$fileOld.length)/1MB -as [int]
			
			Remove-Item $newFile -Force
				
				If ($confDelNew -eq $False)
				{
					Write-Output "$($time.Invoke()) EXCEPTION: New file is over 25% smaller ($($diffErr)MB). $newFile deleted." | Out-File $logPath -Append
					Write-Output "$($time.Invoke()) FAILOVER: Re-encoding $oldFile with Handbrake." | Out-File $logPath -Append
				}
				Else 
				{
					Remove-Item $newFile -Force
					Write-Output "$($time.Invoke()) EXCEPTION: New file is over 25% smaller ($($diffErr)MB). $newFile deleted." | Out-File $logPath -Append
					Write-Output "$($time.Invoke()) FAILOVER: Re-encoding $oldFile with Handbrake." | Out-File $logPath -Append
		
					# Begin Handbrake encode (lossy)
					# Handbrake CLI: https://trac.handbrake.fr/wiki/CLIGuide#presets
						
					<#----------------------------------------------------------------------------------
					HandbrakeCLI arguments
					----------------------------------------------------------------------------------#>
					$hbArg1 = "-i"
					$hbArg2 = "$oldFile"
					$hbArg3 = "-o"
					$hbArg4 = "$newFile"
					$hbArg5 = "-f"
					$hbArg6 = "mp4"
					$hbArg7 = "-a"
					$hbArg8 = "1,2,3,4,5,6,7,8,9,10"
					$hbArg9 = "--subtitle"
					$hbArg10 = "scan,1,2,3,4,5,6,7,8,9,10"
					$hbArg11 = "--x264-profile"
					$hbArg12 = "high"
					$hbArg13 = "--verbose=1"
					$hbArgs = @($hbArg1, $hbArg2, $hbArg3, $hbArg4, $hbArg5, $hbArg6, $hbArg7, $hbArg8, $hbArg9, $hbArg10, $hbArg11, $hbArg12, $hbArg13)
					$hbCMD = &$handbrake $hbArgs
			
					<#----------------------------------------------------------------------------------
					Begin HandbrakeCLI conversion (lossy) with supplied arguments
					-----------------------------------------------------------------------------------#>
					$hbCMD
					Write-Output "$($time.Invoke()) Handbrake finished." | Out-File $logPath -Append
					Remove-Item $oldFile -Force
					If ($confDelOld -eq $False)
					{
						Write-Output "$($time.Invoke()) $oldFile deleted." | Out-File $logPath -Append
					}
					Else 
					{
						Remove-Item $oldFile -Force
						Write-Output "$($time.Invoke()) $oldFile deleted." | Out-File $logPath -Append
					}		
				}
		}		
		# If new file is smaller than old file, log status and delete old file
		Elseif ($fileNew.length -lt $fileOld.length)
		{
			$diffLT = [Math]::Round($fileOld.length-$fileNew.length)/1MB -as [int]
			Remove-Item $oldFile -Force
				
			If ($confDelOld -eq $False)
			{
				Write-Output "$($time.Invoke()) New file is $($diffLT)MB smaller. $oldFile deleted." | Out-File $logPath -Append
			}
			Else 
			{
				Remove-Item $oldFile -Force
				Write-Output "$($time.Invoke()) New file is $($diffLT)MB smaller. $oldFile deleted." | Out-File $logPath -Append
		
			}			
		}
}