<#======================================================================================================================
conv2mp4-ps v3.0 RELEASE - https://github.com/BrianDMG/conv2mp4-ps

This Powershell script will recursively search through a user-defined file path and convert all videos of user-specified 
filetypes to MP4 with H264 video and AAC audio using ffmpeg. If a conversion failure is detected, the script re-encodes
the file with HandbrakeCLI. Upon successful encoding, Plex libraries are refreshed and source file is deleted. 
The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server.
========================================================================================================================

ffmpeg : https://ffmpeg.org/download.html
handbrakecli : https://handbrake.fr/downloads.php #>

<#----------------------------------------------------------------------------------------------------------------------
User-defined variables
------------------------------------------------------------------------------------------------------------------------#>
#Create a backup of the cfg file
	$cfgFile = Join-Path "$PSScriptRoot" "cfg_conv2mp4-ps.ps1"	
	Copy-Item $cfgFile "$cfgFile.bk"
	Write-Host "`nCreated a backup of $cfgFile" -Foregroundcolor Green
#Load variables from cfg_conv2mp4-ps.ps1
	$testCfg = Test-Path $cfgFile
	If ($testCfg -eq $True)
	{
		. $cfgFile
	}
	else 
	{
		Write-Output "Cannot find $cfgFile. Make sure it's in the same directory as the script."
		Start-Sleep 10
		Exit	
	}
<#----------------------------------------------------------------------------------
Static variables 
----------------------------------------------------------------------------------#>
#Script version information
	$version = "v3.0 RELEASE"
#Create lock file (for the purpose of ensuring only one instance of this script is running)
	$lockPath = "$PSScriptRoot"
	$lockFile = "conv2mp4-ps.lock"	
	$lock = Join-Path "$lockPath" "$lockFile"
	$testLock = test-path -LiteralPath $lock
	If ($testLock -eq $True)
	{
		Write-Host "Script is already running in another instance. Waiting..." -ForegroundColor Red
		Do
		{
			$testLock = test-path $lock
			$testLock > $null
			Start-Sleep 10
		}
		Until ($testLock -eq $False)
		Write-Host "Other instance ended. We are cleared for takeoff." -ForegroundColor Green
	}
	new-item $lock
	Clear-Host
# Time and format used for timestamps in the log
	$time = {Get-Date -format "MM/dd/yy HH:mm:ss"}
#Join-Path for log file
	$log = Join-Path "$logPath" "$logName"
# Print initial wait notice to console
	Write-Host "`nBuilding file list, please wait. This may take a while, especially for large libraries.`n"
# Get current time to store as start time for script
	$script:scriptDurStart = (Get-Date -format "HH:mm:ss")
# Build and test file paths to executables and log 
	$ffmpeg = Join-Path "$ffmpegBinDir" "ffmpeg.exe"
	$testFFMPath = Test-Path $ffmpeg
		If ($testFFMPath -eq $False)
		{
			Write-Output "`nffmeg.exe could not be found at $($ffmpegBinDir)." | Tee-Object -filepath $log -append
			Write-Output "Ensure the path in `$ffmpegBinDir is correct." | Tee-Object -filepath $log -append
			Write-Output "Aborting script." | Tee-Object -filepath $log -append
			Try
			{
				Remove-Item $lock -Force -ErrorAction Stop
			}	
			Catch
			{	
				Log "$($time.Invoke()) ERROR: $lock could not be deleted. Please delete manually. "
			}
			Exit
		}
		Else
		{
		}
	$ffprobe = Join-Path "$ffmpegBinDir" "ffprobe.exe"
	$testFFPPath = Test-Path $ffprobe
		If ($testFFPPath -eq $False)
		{
			Write-Output "`nffprobe.exe could not be found at $($ffmpegBinDir)." | Tee-Object -filepath $log -append
			Write-Output "Ensure the path in `$ffmpegBinDir is correct." | Tee-Object -filepath $log -append
			Write-Output "Aborting script." | Tee-Object -filepath $log -append
			Try
			{
				Remove-Item $lock -Force -ErrorAction Stop
			}	
			Catch
			{	
				Log "$($time.Invoke()) ERROR: $lock could not be deleted. Please delete manually. "
			}
			Exit
		}
		Else
		{
		}
	$handbrake = Join-Path "$handbrakeDir" "HandBrakeCLI.exe"
	$testHBPath = Test-Path $handbrake
		If ($testHBPath -eq $False)
		{
			Write-Output "`nhandbrakecli.exe could not be found at $($handbrakeDir)." | Tee-Object -filepath $log -append
			Write-Output "Ensure the path in `$handbrakeDir is correct." | Tee-Object -filepath $log -append
			Write-Output "Aborting script." | Tee-Object -filepath $log -append
			Exit
		}
		Else
		{
		}
# Setup for file list loop
	$testMediaPath = Test-Path $mediaPath
	If ($testMediaPath -eq $True)
	{
		$mPath = Get-Item -Path $mediaPath
	}
	Else
	{
		Write-Output "`nPath not found: $mediaPath" | Tee-Object -filepath $log -append
		Write-Output "Ensure the path in `$mediaPath exists and is accessible." | Tee-Object -filepath $log -append
		Write-Output "Aborting script." | Tee-Object -filepath $log -append
		Try
		{
			Remove-Item $lock -Force -ErrorAction Stop
		}	
		Catch
		{	
			Log "$($time.Invoke()) ERROR: $lock could not be deleted. Please delete manually. "
		}
		Exit
	}
	$b=0
	$fileList = Get-ChildItem "$($mPath.FullName)\*" -i $fileTypes -recurse | ForEach-Object {$b++; If ($b -eq 1){Write-Host -NoNewLine "`rFound $b file so far..."} Else{Write-Host -NoNewLine "`rFound $b files so far..." -foregroundcolor green};$_}
	$num = $fileList | measure
	$fileCount = $num.count
# Initialize disk usage change to 0
	$diskUsage = 0
# Initialize 'video length converted' to 0
	$durTotal = [timespan]::fromseconds(0)

<#----------------------------------------------------------------------------------
Functions 
----------------------------------------------------------------------------------#>
# Logging and console output
	Function Log
	{
	   Param ([string]$logString)
	   Write-Output $logString | Tee-Object -filepath $log -append
	}
# Prints the current script version header	
	Function PrintVersion
	{
		Log "conv2mp4-ps $version - https://github.com/BrianDMG/conv2mp4-ps"
		Log "------------------------------------------------------------------------------------"
	}
# Append log conditions
	Function AppendLog
	{
		#Check whether log file is empty
			$logEmpty = Get-Content $log
		#Should the log append or clear
			If ($appendLog -eq $False)
			{
				Clear-Content $log
				PrintVersion
			}
			Elseif ($appendLog -eq $True -AND $logEmpty -eq $Null)
			{
				PrintVersion
			}
			Else
			{
				Log "`n------------------------------------------------------------------------------------"
				Log ">>>>> New Session (started $($time.Invoke()))"
			}
	}
# List files in the queue in the log
	Function ListFiles
	{			 
		If ($fileCount -eq 1)
		{
			AppendLog
			Log ("`nThere is $fileCount file in the queue:`n")
		}
		Elseif ($fileCount -gt 1)
		{
			AppendLog
			Log ("`nThere are $fileCount files in the queue:`n")
		}
		Else
		{
			Write-Host ("`nThere are no files to be converted in $mediaPath. Congrats!`n")
			Try
			{
				Remove-Item $lock -Force -ErrorAction Stop
			}	
			Catch
			{	
				Log "$($time.Invoke()) ERROR: $lock could not be deleted. Please delete manually. "
			}	
			Exit
		}
		
		$num = 0
			ForEach ($file in $fileList)
				{
					$num++
					Log "$($num). $file"
				}
				Log ""
	}
# Find out what video and audio codecs a file is using
	Function CodecDiscovery
	{
		# Check video codec with ffprobe	
			$vCodecArg1 = "-v"
			$vCodecArg2 = "error"
			$vCodecArg3 = "-select_streams"
			$vCodecArg4 = "v:0"
			$vCodecArg5 = "-show_entries"
			$vCodecArg6 = "stream=codec_name"
			$vCodecArg7 = "-of"
			$vCodecArg8 = "default=nokey=1:noprint_wrappers=1"
			$vCodecArg9 = "$oldFile"
			$vCodecArgs = @($vCodecArg1, $vCodecArg2, $vCodecArg3, $vCodecArg4, $vCodecArg5, $vCodecArg6, $vCodecArg7, $vCodecArg8, $vCodecArg9)
			$script:vCodecCMD = &$ffprobe $vCodecArgs
		# Check audio codec with ffprobe
			$aCodecArg1 = "-v"
			$aCodecArg2 = "error"
			$aCodecArg3 = "-select_streams"
			$aCodecArg4 = "a:0"
			$aCodecArg5 = "-show_entries"
			$aCodecArg6 = "stream=codec_name"
			$aCodecArg7 = "-of"
			$aCodecArg8 = "default=nokey=1:noprint_wrappers=1"
			$aCodecArg9 = "$oldFile"
			$aCodecArgs = @($aCodecArg1, $aCodecArg2, $aCodecArg3, $aCodecArg4, $aCodecArg5, $aCodecArg6, $aCodecArg7, $aCodecArg8, $aCodecArg9)
			$script:aCodecCMD = &$ffprobe $aCodecArgs	
		#Get duration of file
			$durArg1 = "-v"
			$durArg2 = "error"
			$durArg3 = "-show_entries"
			$durArg4 = "format=duration"
			$durArg5 = "-of"
			$durArg6 = "default=noprint_wrappers=1:nokey=1"
			$durArg7 = "$oldFile"
			$durArgs = @($durArg1, $durArg2, $durArg3, $durArg4, $durArg5, $durArg6, $durArg7)
			$durCMD = &$ffprobe $durArgs
			$durTemp = [timespan]::fromseconds($durCMD)
			$script:durTicks = $durTemp.ticks
			If ($durTemp -eq 0 -OR $durTemp -eq "N/A")
			{
				$script:duration = "00:01:00"
			}
			Else
			{
				$script:duration = "$($durTemp.hours):$($durTemp.minutes):$($durTemp.seconds)"
			}
	}
# If new and old files are the same size
	Function IfSame
	{		
			Try
			{
				Remove-Item $oldFile -Force -ErrorAction Stop
				Log "$($time.Invoke()) Same file size."
				Log "$($time.Invoke()) $oldFile deleted."
			}	
			Catch
			{	
				Log "$($time.Invoke()) ERROR: $oldFile could not be deleted. Full error below."
				Log $_
			}				
	}
# If new file is larger than old file
	Function IfLarger
       {
           $diffGT = [Math]::Round($fileNew.length-$fileOld.length)/1MB -as [int]
 
			Try
            {
                Remove-Item $oldFile -Force -ErrorAction Stop
                Log "$($time.Invoke()) $oldFile deleted."
				
				If ($diffGT -lt 1)
				{
					$diffGT_KB = ($diffGT * 1000)
					Log "$($time.Invoke()) New file is $($diffGT_KB)KB larger."
				}
				Elseif ($diffGT -gt 1000)
				{
					$diffGT_GB = ($diffGT / 1000)
					Log "$($time.Invoke()) New file is $($diffGT_GB)GB larger."
				}
				Else
				{
					Log "$($time.Invoke()) New file is $($diffGT)MB larger."
				}
				
				$script:diskUsage = $script:diskUsage + $diffGT
				
					If ($script:diskUsage -gt -1 -AND $script:diskUsage -lt 1)
					{
						$diskUsage_KB = ($script:diskUsage * 1000)
						Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsage_KB)KB"
					}
					Elseif ($script:diskUsage -lt -1000 -OR $script:diskUsage -gt 1000)
					{
						$diskUsage_GB = ($script:diskUsage / 1000)
						Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsage_GB)GB"					
					}
					Else
					{
						Log "$($time.Invoke()) Current cumulative storage difference: $($script:diskUsage)MB"					
					}
			}           
            Catch
            {
                Log "$($time.Invoke()) ERROR: $oldFile could not be deleted. Full error below."
                Log $_
            }
       }
# If new file is smaller than old file
	Function IfSmaller
	{
		$diffLT = [Math]::Round($fileOld.length-$fileNew.length)/1MB -as [int]
			
			Try
			{
				Remove-Item $oldFile -Force -ErrorAction Stop
				Log "$($time.Invoke()) $oldFile deleted."
				
				If ($diffLT -lt 1)
				{
					$diffLT_KB = ($diffLT * 1000)
					Log "$($time.Invoke()) New file is $($diffLT_KB)KB smaller."
				}
				Elseif ($diffLT -lt -1000)
				{
					$diffLT_GB = ($diffLT / 1000)
					Log "$($time.Invoke()) New file is $($diffLT_GB)GB smaller."
				}
				Else
				{
				Log "$($time.Invoke()) New file is $($diffLT)MB smaller."
				}
				
				$script:diskUsage = $script:diskUsage - $diffLT
				
					If ($script:diskUsage -gt -1 -AND $script:diskUsage -lt 1)
					{
						$diskUsage_KB = ($script:diskUsage * 1000)
						Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsage_KB)KB"
					}
					Elseif ($script:diskUsage -lt -1000 -OR $script:diskUsage -gt 1000)
					{
						$diskUsage_GB = ($script:diskUsage / 1000)
						Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsage_GB)GB"					
					}
					Else
					{
						Log "$($time.Invoke()) Current cumulative storage difference: $($script:diskUsage)MB"					
					}
			}
			Catch
			{
				Log "$($time.Invoke()) ERROR: $oldFile could not be deleted. Full error below."
				Log $_
			}
	}
## If new file is over 25% smaller than the original file, trigger encoding failure
	Function FailureDetected
	{
		$diffErr = [Math]::Round($fileNew.length-$fileOld.length)/1MB -as [int]
						
		Try
		{
			Remove-Item $newFile -Force -ErrorAction Stop
			Log "$($time.Invoke()) EXCEPTION: New file is over 25% smaller ($($diffErr)MB). $newFile deleted."
			Log "$($time.Invoke()) FAILOVER: Re-encoding $oldFile with Handbrake."
		}
		Catch
		{
			Log "$($time.Invoke()) ERROR: $newFile could not be deleted. Full error below."
			Log $_
		}
	}
# If a file video codec is already H264 and audio codec is already AAC, use these arguments
	Function SimpleConvert	
	{	
		Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Performing simple container conversion to MP4."
		
		If ($keepSubs -eq $True)
		{
			# ffmpeg arguments
				$ffArg1 = "-n"
				$ffArg2 = "-fflags"
				$ffArg3 = "+genpts"
				$ffArg4 = "-i"
				$ffArg5 = "$oldFile"
				$ffArg6 = "-threads"
				$ffArg7 = "6"
				$ffArg8 = "-map"
				$ffArg9 = "0"
				$ffArg10 = "-c:v"
				$ffArg11 = "copy"
				$ffArg12 = "-c:a"
				$ffArg13 = "copy"
				$ffArg14 = "-c:s"
				$ffArg15 = "mov_text"
				$ffArg16 = "$newFile"
				$ffArgs = @($ffArg1, $ffArg2, $ffArg3, $ffArg4, $ffArg5, $ffArg6, $ffArg7, $ffArg8, $ffArg9, $ffArg10, $ffArg11, $ffArg12, $ffArg13, $ffArg14, $ffArg15, $ffArg16)
				$ffCMD = &$ffmpeg $ffArgs
		
			# Begin ffmpeg operation
				$ffCMD
				Log "$($time.Invoke()) ffmpeg completed"
		}
		Else
		{
			# ffmpeg arguments
				$ffArg1 = "-n"
				$ffArg2 = "-fflags"
				$ffArg3 = "+genpts"
				$ffArg4 = "-i"
				$ffArg5 = "$oldFile"
				$ffArg6 = "-threads"
				$ffArg7 = "6"
				$ffArg8 = "-map"
				$ffArg9 = "0"
				$ffArg10 = "-c:v"
				$ffArg11 = "copy"
				$ffArg12 = "-c:a"
				$ffArg13 = "copy"
				$ffArg14 = "-sn"
				$ffArg15 = "$newFile"
				$ffArgs = @($ffArg1, $ffArg2, $ffArg3, $ffArg4, $ffArg5, $ffArg6, $ffArg7, $ffArg8, $ffArg9, $ffArg10, $ffArg11, $ffArg12, $ffArg13, $ffArg14, $ffArg15)
				$ffCMD = &$ffmpeg $ffArgs
		
			# Begin ffmpeg operation
				$ffCMD
				Log "$($time.Invoke()) ffmpeg completed"
		}
	}
# If a file video codec is already H264, but audio codec is not AAC, use these arguments
	Function EncodeAudio
	{
		Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding audio to AAC"
			
		If ($keepSubs -eq $True)
		{
			# ffmpeg arguments
				$ffArg1 = "-n"
				$ffArg2 = "-fflags"
				$ffArg3 = "+genpts"
				$ffArg4 = "-i"
				$ffArg5 = "$oldFile"
				$ffArg6 = "-threads"
				$ffArg7 = "6"
				$ffArg8 = "-map"
				$ffArg9 = "0"
				$ffArg10 = "-c:v"
				$ffArg11 = "copy"
				$ffArg12 = "-c:a"
				$ffArg13 = "aac"
				$ffArg14 = "-c:s"
				$ffArg15 = "mov_text"
				$ffArg16 = "$newFile"
				$ffArgs = @($ffArg1, $ffArg2, $ffArg3, $ffArg4, $ffArg5, $ffArg6, $ffArg7, $ffArg8, $ffArg9, $ffArg10, $ffArg11, $ffArg12, $ffArg13, $ffArg14, $ffArg15, $ffArg16)
				$ffCMD = &$ffmpeg $ffArgs
		
			# Begin ffmpeg operation
				$ffCMD
				Log "$($time.Invoke()) ffmpeg completed"
		}
		Else
		{
			# ffmpeg arguments
				$ffArg1 = "-n"
				$ffArg2 = "-fflags"
				$ffArg3 = "+genpts"
				$ffArg4 = "-i"
				$ffArg5 = "$oldFile"
				$ffArg6 = "-threads"
				$ffArg7 = "6"
				$ffArg8 = "-map"
				$ffArg9 = "0"
				$ffArg10 = "-c:v"
				$ffArg11 = "copy"
				$ffArg12 = "-c:a"
				$ffArg13 = "aac"
				$ffArg14 = "-sn"
				$ffArg15 = "$newFile"
				$ffArgs = @($ffArg1, $ffArg2, $ffArg3, $ffArg4, $ffArg5, $ffArg6, $ffArg7, $ffArg8, $ffArg9, $ffArg10, $ffArg11, $ffArg12, $ffArg13, $ffArg14, $ffArg15)
				$ffCMD = &$ffmpeg $ffArgs
		
			# Begin ffmpeg operation
				$ffCMD
				Log "$($time.Invoke()) ffmpeg completed"
		}
	}
# If a file video codec is not H264, and audio codec is already AAC, use these arguments
	Function EncodeVideo
	{
		Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding video to H264."
	
		If ($keepSubs -eq $True)
		{
			# ffmpeg arguments
				$ffArg1 = "-n"
				$ffArg2 = "-fflags"
				$ffArg3 = "+genpts"
				$ffArg4 = "-i"
				$ffArg5 = "$oldFile"
				$ffArg6 = "-threads"
				$ffArg7 = "6"
				$ffArg8 = "-map"
				$ffArg9 = "0"
				$ffArg10 = "-c:v"
				$ffArg11 = "libx264"
				$ffArg12 = "-preset"
				$ffArg13 = "medium"
				$ffArg14 = "-crf"
				$ffArg15 = "18"
				$ffArg16 = "-c:a"
				$ffArg17 = "copy"
				$ffArg18 = "-c:s"
				$ffArg19 = "mov_text"
				$ffArg20 = "$newFile"
				$ffArgs = @($ffArg1, $ffArg2, $ffArg3, $ffArg4, $ffArg5, $ffArg6, $ffArg7, $ffArg8, $ffArg9, $ffArg10, $ffArg11, $ffArg12, $ffArg13, $ffArg14, $ffArg15, $ffArg16, $ffArg17, $ffArg18, $ffArg19, $ffArg20)
				$ffCMD = &$ffmpeg $ffArgs
		
			# Begin ffmpeg operation
				$ffCMD
				Log "$($time.Invoke()) ffmpeg completed"
		}
		Else
		{
			# ffmpeg arguments
				$ffArg1 = "-n"
				$ffArg2 = "-fflags"
				$ffArg3 = "+genpts"
				$ffArg4 = "-i"
				$ffArg5 = "$oldFile"
				$ffArg6 = "-threads"
				$ffArg7 = "6"
				$ffArg8 = "-map"
				$ffArg9 = "0"
				$ffArg10 = "-c:v"
				$ffArg11 = "libx264"
				$ffArg12 = "-preset"
				$ffArg13 = "medium"
				$ffArg14 = "-crf"
				$ffArg15 = "18"
				$ffArg16 = "-c:a"
				$ffArg17 = "copy"
				$ffArg18 = "-sn"
				$ffArg19 = "$newFile"
				$ffArgs = @($ffArg1, $ffArg2, $ffArg3, $ffArg4, $ffArg5, $ffArg6, $ffArg7, $ffArg8, $ffArg9, $ffArg10, $ffArg11, $ffArg12, $ffArg13, $ffArg14, $ffArg15, $ffArg16, $ffArg17, $ffArg18, $ffArg19)
				$ffCMD = &$ffmpeg $ffArgs

			# Begin ffmpeg operation
				$ffCMD
				Log "$($time.Invoke()) ffmpeg completed"
		}
	}
# If a file video codec is not H264, and audio codec is not AAC, use these arguments
	Function EncodeBoth
	{	
		Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding video to H264 and audio to AAC."
	
		If ($keepSubs -eq $True)
		{
			# ffmpeg arguments
				$ffArg1 = "-n"
				$ffArg2 = "-fflags"
				$ffArg3 = "+genpts"
				$ffArg4 = "-i"
				$ffArg5 = "$oldFile"
				$ffArg6 = "-threads"
				$ffArg7 = "6"
				$ffArg8 = "-map"
				$ffArg9 = "0"
				$ffArg10 = "-c:v"
				$ffArg11 = "libx264"
				$ffArg12 = "-preset"
				$ffArg13 = "fast"
				$ffArg14 = "-crf"
				$ffArg15 = "18"
				$ffArg16 = "-c:a"
				$ffArg17 = "aac"
				$ffArg18 = "-c:s"
				$ffArg19 = "mov_text"
				$ffArg20 = "$newFile"
				$ffArgs = @($ffArg1, $ffArg2, $ffArg3, $ffArg4, $ffArg5, $ffArg6, $ffArg7, $ffArg8, $ffArg9, $ffArg10, $ffArg11, $ffArg12, $ffArg13, $ffArg14, $ffArg15, $ffArg16, $ffArg17, $ffArg18, $ffArg19, $ffArg20)
				$ffCMD = &$ffmpeg $ffArgs
				
			# Begin ffmpeg operations
				$ffCMD
				Log "$($time.Invoke()) ffmpeg completed"	
		}
		Else
		{
			# ffmpeg arguments
				$ffArg1 = "-n"
				$ffArg2 = "-fflags"
				$ffArg3 = "+genpts"
				$ffArg4 = "-i"
				$ffArg5 = "$oldFile"
				$ffArg6 = "-threads"
				$ffArg7 = "6"
				$ffArg8 = "-map"
				$ffArg9 = "0"
				$ffArg10 = "-c:v"
				$ffArg11 = "libx264"
				$ffArg12 = "-preset"
				$ffArg13 = "fast"
				$ffArg14 = "-crf"
				$ffArg15 = "18"
				$ffArg16 = "-c:a"
				$ffArg17 = "aac"
				$ffArg18 = "-sn"
				$ffArg19 = "$newFile"
				$ffArgs = @($ffArg1, $ffArg2, $ffArg3, $ffArg4, $ffArg5, $ffArg6, $ffArg7, $ffArg8, $ffArg9, $ffArg10, $ffArg11, $ffArg12, $ffArg13, $ffArg14, $ffArg15, $ffArg16, $ffArg17, $ffArg18, $ffArg19)
				$ffCMD = &$ffmpeg $ffArgs
				
			# Begin ffmpeg operations
				$ffCMD
				Log "$($time.Invoke()) ffmpeg completed"
		}
	}	
#If new file is much smaller than old file (indicating a failed conversion), log status, delete new file, and re-encode with HandbrakeCLI
	Function EncodeHandbrake
	{
		If ($keepSubs -eq $True)
		{
			# Handbrake CLI: https://trac.handbrake.fr/wiki/CLIGuide#presets 
			# Handbrake arguments
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
				$hbArg11 = "-e"
				$hbArg12 = "x264"
				$hbArg13 = "--encoder-preset"
				$hbArg14 = "slow"
				$hbArg15 = "--encoder-profile"
				$hbArg16 = "high"
				$hbArg17 = "--encoder-level"
				$hbArg18 = "4.1"
				$hbArg19 = "-q"
				$hbArg20 = "18"
				$hbArg21 = "-E"
				$hbArg22 = "aac"
				$hbArg23 = "--audio-copy-mask"
				$hbArg24 = "aac"
				$hbArg25 = "--verbose=1"
				$hbArg26 = "--decomb" 
				$hbArg27 = "--loose-anamorphic"
				$hbArg28 = "--modulus" 
				$hbArg29 = "2"
				$hbArgs = @($hbArg1, $hbArg2, $hbArg3, $hbArg4, $hbArg5, $hbArg6, $hbArg7, $hbArg8, $hbArg9, $hbArg10, $hbArg11, $hbArg12, $hbArg13, $hbArg14, $hbArg15, $hbArg16, $hbArg17, $hbArg18, $hbArg19, $hbArg20, $hbArg21, $hbArg22, $hbArg23, $hbArg24, $hbArg25, $hbArg26, $hbArg27. $hbArg28. $hbArg29)
				$hbCMD = &$handbrake $hbArgs
			# Begin Handbrake operation
				Try 
				{
					$hbCMD
					Log "$($time.Invoke()) Handbrake finished."
				}
				Catch
				{
					Log "$($time.Invoke()) ERROR: Handbrake has encountered an error."
					Log $_
				}
		}
		Else
		{
			# Handbrake CLI: https://trac.handbrake.fr/wiki/CLIGuide#presets 
			# Handbrake arguments
				$hbArg1 = "-i"
				$hbArg2 = "$oldFile"
				$hbArg3 = "-o"
				$hbArg4 = "$newFile"
				$hbArg5 = "-f"
				$hbArg6 = "mp4"
				$hbArg7 = "-a"
				$hbArg8 = "1,2,3,4,5,6,7,8,9,10"
				$hbArg9 = "-e"
				$hbArg10 = "x264"
				$hbArg11 = "--encoder-preset"
				$hbArg12 = "slow"
				$hbArg13 = "--encoder-profile"
				$hbArg14 = "high"
				$hbArg15 = "--encoder-level"
				$hbArg16 = "4.1"
				$hbArg17 = "-q"
				$hbArg18 = "18"
				$hbArg19 = "-E"
				$hbArg20 = "aac"
				$hbArg21 = "--audio-copy-mask"
				$hbArg22 = "aac"
				$hbArg23 = "--verbose=1"
				$hbArg24 = "--decomb" 
				$hbArg25 = "--loose-anamorphic"
				$hbArg26 = "--modulus" 
				$hbArg27 = "2"
				$hbArgs = @($hbArg1, $hbArg2, $hbArg3, $hbArg4, $hbArg5, $hbArg6, $hbArg7, $hbArg8, $hbArg9, $hbArg10, $hbArg11, $hbArg12, $hbArg13, $hbArg14, $hbArg15, $hbArg16, $hbArg17, $hbArg18, $hbArg19, $hbArg20, $hbArg21, $hbArg22, $hbArg23, $hbArg24, $hbArg25, $hbArg26, $hbArg27)
				$hbCMD = &$handbrake $hbArgs
			# Begin Handbrake operation
				Try 
				{
					$hbCMD
					Log "$($time.Invoke()) Handbrake finished."
				}
				Catch
				{
					Log "$($time.Invoke()) ERROR: Handbrake has encountered an error."
					Log $_
				}
		}
	}
# Delete garbage files
	Function GarbageCollection
	{
		$garbageList = Get-ChildItem "$($mPath.FullName)\*" -i $script:garbage -recurse
		$garbageNum = 0

			ForEach ($turd in $garbageList)
			{
				$garbageNum++
			}	
		
				If ($garbageNum -eq 1)
				{
					Log "`nGarbage Collection: The following file was deleted:"
				}
				Elseif ($garbageNum -gt 1)
				{
					Log "`nGarbage Collection: The following $garbageNum files were deleted:"
				}
				Else
				{
					Log ("`nGarbage Collection: No garbage found in $mediaPath. Congrats!")
				}
				Log ""
			
		$garbageNum = 0
		
			ForEach ($turd in $garbageList)
			{
				$garbageNum++
				Log "$($garbageNum). $turd"
					Try
					{
						Remove-Item $turd -Force -ErrorAction Stop
					}
					Catch
					{
						Log "$($time.Invoke()) ERROR: $turd could not be deleted. Full error below."
						Log $_
					}
			}	
	}
# Log various session statistics 
	Function FinalStatistics
	{
		Log "`n====================================================================================`n"
		#Print total session disk usage changes
			If ($script:diskUsage -gt -1 -AND $script:diskUsage -lt 1)
			{
				$diskUsage_KB = ($script:diskUsage * 1000)
				Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsage_KB)KB"
			}
			Elseif ($script:diskUsage -lt -1000 -OR $script:diskUsage -gt 1000)
			{
				$diskUsage_GB = ($script:diskUsage / 1000)
				Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsage_GB)GB"					
			}
			Else
			{
				Log "$($time.Invoke()) Total cumulative storage difference: $($script:diskUsage)MB"					
			}
		#Do some time math to get total script runtime
			$script:scriptDurTemp = new-timespan $script:scriptDurStart $(get-date -format "HH:mm:ss")
			$script:scriptDurTotal = "$($script:scriptDurTemp.hours):$($script:scriptDurTemp.minutes):$($script:scriptDurTemp.seconds)"
			Log "`n$script:durTotal of video processed in $script:scriptDurTotal"
		#Do some math/rounding to get session average conversion speed	
			Try
			{
				$avgConv = $script:durTicksTotal / $script:scriptDurTemp.Ticks
				$avgConv = [math]::Round($avgConv,2)
				Log "Average conversion speed of $($avgConv)x"
			}
			Catch
			{
				Log "No time elapsed."
			}
			
		Log "`n===================================================================================="
	}
	
<#----------------------------------------------------------------------------------
Begin search loop 
----------------------------------------------------------------------------------#>
# List files in the queue in the log
	ListFiles

# Begin performing operations of files
	$i = 0

	ForEach ($file in $fileList)
	{
		$i++;
		$oldFile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;
		If ($useOutPath -eq $True)
		{
			$newFile = $outPath + "\" + $file.BaseName + ".mp4";
			Log "outPath = $outPath"
		}
		Else
		{
			$newFile = $file.DirectoryName + "\" + $file.BaseName + ".mp4";
		}
		$plexURL = "http://$plexIP/library/sections/all/refresh?X-Plex-Token=$plexToken"
		$progress = ($i / $fileCount) * 100
		$progress = [Math]::Round($progress,2)
					
		Log "------------------------------------------------------------------------------------"
		Log "$($time.Invoke()) Processing - $oldFile"
		Log "$($time.Invoke()) File $i of $fileCount - Total queue $progress%"

		<#----------------------------------------------------------------------------------
		Test if $newFile (.mp4) already exists, if yes then delete $oldFile (.mkv)
		This outputs a more specific log message acknowleding the file already existed.
		----------------------------------------------------------------------------------#>
		$testNewExist = Test-Path $newFile
		If ($testNewExist -eq $True)
		{
			Remove-Item $oldFile -Force
			Log "$($time.Invoke()) $newFile already exists."
			Log "$($time.Invoke()) Deleting $oldFile."
		}
		Else
		{
		<#----------------------------------------------------------------------------------
		Codec discovery to determine whether video, audio, or both needs to be encoded
		----------------------------------------------------------------------------------#>
		CodecDiscovery
			
		<#----------------------------------------------------------------------------------
		Statistics-gathering derived from Codec Discovery 
		----------------------------------------------------------------------------------#>
		#Running tally of session container duration (cumulative length of video processed)
			$script:durTotal = $script:durTotal + $script:duration
		#Running tally of ticks (time expressed as an integer) for script runtime
			$script:durTicksTotal = $script:durTicksTotal + $script:durTicks 
			
		<#----------------------------------------------------------------------------------
		Begin ffmpeg conversion based on codec discovery 
		----------------------------------------------------------------------------------#>			
		# Video is already H264, Audio is already AAC
			If ($vCodecCMD -eq "h264" -AND $aCodecCMD -eq "aac") 
			{
				SimpleConvert
			}
		# Video is already H264, Audio is not AAC
			ElseIf ($vCodecCMD -eq "h264" -AND $aCodecCMD -ne "aac") 
			{
				EncodeAudio
			}	
		# Video is not H264, Audio is already AAC
			ElseIf ($vCodecCMD -ne "h264" -AND $aCodecCMD -eq "aac")
			{
				EncodeVideo
			}
		# Video is not H264, Audio is not AAC
			ElseIf ($vCodecCMD -ne "h264" -AND $aCodecCMD -ne "aac")
			{
				EncodeBoth
			}
			# Refresh Plex libraries
				Invoke-WebRequest $plexURL -UseBasicParsing
				Log "$($time.Invoke()) Plex libraries refreshed"
								
			<#----------------------------------------------------------------------------------
			Begin file comparison between old file and new file to determine conversion success
			-----------------------------------------------------------------------------------#>
			# Load files for comparison
				$fileOld = Get-Item $oldFile
				$fileNew = Get-Item $newFile
							
			# If new file is the same size as old file, log status and delete old file
				If ($fileNew.length -eq $fileOld.length) 
				{
					IfSame
				}						
			# If new file is larger than old file, log status and delete old file
				Elseif ($fileNew.length -gt $fileOld.length) 
				{
					IfLarger
				}			
			# If new file is much smaller than old file (indicating a failed conversion), log status, delete new file, and re-encode with HandbrakeCLI
				Elseif ($fileNew.length -lt ($fileOld.length * .75))
				{
					FailureDetected
						
						<#----------------------------------------------------------------------------------
						Begin Handbrake encode (lossy)
						----------------------------------------------------------------------------------#>
						EncodeHandbrake
								
							# Load files for comparison
								$fileOld = Get-Item $oldFile
								$fileNew = Get-Item $newFile
								
							# If new file is much smaller than old file (likely because the script was aborted re-encode), leave original file alone and print error
								If ($fileNew.length -lt ($fileOld.length * .75))
								{
									$diffErr = [Math]::Round($fileNew.length-$fileOld.length)/1MB -as [int]
									Try
									{
										Remove-Item $newFile -Force -ErrorAction Stop
										Log "$($time.Invoke()) ERROR: New file was too small ($($diffErr)MB)."
										Log "$($time.Invoke()) Deleted new file and retained $oldFile."						
									}
									Catch
									{
										Log "$($time.Invoke()) ERROR: New file was too small ($($diffErr)MB). Retained $oldFile."
										Log "$($time.Invoke()) ERROR: $newFile could not be deleted. Full error below."
										Log $_
									}								
								}
							# If new file is the same size as old file, log status and delete old file
								Elseif ($fileNew.length -eq $fileOld.length) 
								{
									IfSame
								}		
							# If new file is larger than old file, log status and delete old file
								Elseif ($fileNew.length -gt $fileOld.length) 
								{
									IfLarger
								}
							# If new file is smaller than old file, log status and delete old file
								Elseif ($fileNew.length -lt $fileOld.length)
								{
									IfSmaller
								}					
					}
									
				# If new file is smaller than old file, log status and delete old file
					Elseif ($fileNew.length -lt $fileOld.length)
					{
						IfSmaller
					}
		}
	} # End foreach loop
	
<#----------------------------------------------------------------------------------
Wrap-up
-----------------------------------------------------------------------------------#>
FinalStatistics
If ($collectGarbage -eq $True)
{
	GarbageCollection
}
Else
{}
#Delete lock file
Try
	{
		Remove-Item $lock -Force -ErrorAction Stop
	}	
Catch
	{	
		Log "$($time.Invoke()) ERROR: $lock could not be deleted. Full error below."
		Log $_
	}	
Log "`nFinished"
Exit