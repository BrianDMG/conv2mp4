<#======================================================================================================================
conv2mp4-ps v3.5 - https://github.com/BrianDMG/conv2mp4-ps

This Powershell script will recursively search through a user-defined file path and convert all videos of user-specified 
filetypes to MP4 with H264 video and AAC audio using ffmpeg. If a conversion failure is detected, the script re-encodes
the file with HandbrakeCLI. Upon successful encoding, Plex libraries are (optionally) refreshed and source file is deleted. 
The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server.
========================================================================================================================

ffmpeg : https://ffmpeg.org/download.html
handbrakecli : https://handbrake.fr/downloads.php #>

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
	if ($fileCount -ge 1)
	{
		AppendLog
		Log ("`nThere are $fileCount file(s) in the queue:`n")
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
Function Find-Codec
{
	param
	(
		[Parameter(Position = 0, mandatory = $true)]
		[ValidateSet("Audio", "Video", "Duration")]
		[String]$DiscoverType
	)
	
	# Check video codec with ffprobe
	$ffprobeArgs += "-v "
	$ffprobeArgs += "error "
	
	If ($DiscoverType -eq "Video")
	{
		$ffprobeArgs += "-select_streams "
		$ffprobeArgs += "v:0 "
		$ffprobeArgs += "-show_entries "
		$ffprobeArgs += "stream=codec_name "
	}
	
	If ($DiscoverType -eq "Audio")
	{
		$ffprobeArgs += "-v "
		$ffprobeArgs += "error "
		$ffprobeArgs += "-select_streams "
		$ffprobeArgs += "a:0 "
		$ffprobeArgs += "-show_entries "
		$ffprobeArgs += "stream=codec_name "
	}
	
	If ($DiscoverType -eq "Duration")
	{
		$ffprobeArgs += "-v "
		$ffprobeArgs += "error "
		$ffprobeArgs += "-show_entries "
		$ffprobeArgs += "format=duration "
	}	
	
	$ffprobeArgs += "-of "
	$ffprobeArgs += "default=noprint_wrappers=1:nokey=1 "
	$ffprobeArgs += "`"$oldFile`""
	
	$ffprobeCMD = cmd.exe /c "$ffprobe $ffprobeArgs"
	
	If ($DiscoverType -eq "Duration")
	{
		$ffprobeTemp = [timespan]::fromseconds($ffprobeCMD)
		$script:durTicks = $ffprobeTemp.ticks
		If ($ffprobeTemp -eq 0 -OR $ffprobeTemp -eq "N/A")
		{
			return "00:01:00"
		}
		Else
		{
			return "$($ffprobeTemp.hours):$($ffprobeTemp.minutes):$($ffprobeTemp.seconds)"
		}
	}
	Else
	{
		return $ffprobeCMD	
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
	$diffGT = [Math]::Round($fileNew.length - $fileOld.length)/1MB
	$diffGT = [Math]::Round($diffGT, 2)
	Try
	{
		Remove-Item -LiteralPath $oldFile -Force -ErrorAction Stop
		Log "$($time.Invoke()) $oldFile deleted."
		
		If ($diffGT -lt 1)
		{
			$diffGT_KB = ($diffGT * 1024)
			$diffGT_KB = [Math]::Round($diffGT_KB, 2)
			Log "$($time.Invoke()) New file is $($diffGT_KB)KB larger."
		}
		Elseif ($diffGT -gt 1024)
		{
			$diffGT_GB = ($diffGT / 1024)
			$diffGT_GB = [Math]::Round($diffGT_GB, 2)
			Log "$($time.Invoke()) New file is $($diffGT_GB)GB larger."
		}
		Else
		{
			Log "$($time.Invoke()) New file is $($diffGT)MB larger."
		}
		
		$script:diskUsage = $script:diskUsage + $diffGT
		
		If ($script:diskUsage -gt -1 -AND $script:diskUsage -lt 1)
		{
			$diskUsage_KB = ($script:diskUsage * 1024)
			$diskUsage_KB = [Math]::Round($diskUsage_KB, 2)
			Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsage_KB)KB"
		}
		Elseif ($script:diskUsage -lt -1024 -OR $script:diskUsage -gt 1024)
		{
			$diskUsage_GB = ($script:diskUsage / 1024)
			$diskUsage_GB = [Math]::Round($diskUsage_GB, 2)
			Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsage_GB)GB"
		}
		Else
		{
			$script:diskUsage = [Math]::Round($script:diskUsage, 2)
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
	$diffLT = [Math]::Round($fileOld.length - $fileNew.length)/1MB
	$diffLT = [Math]::Round($diffLT, 2)
	Try
	{
		Remove-Item -LiteralPath $oldFile -Force -ErrorAction Stop
		Log "$($time.Invoke()) $oldFile deleted."
		
		If ($diffLT -lt 1)
		{
			$diffLT_KB = ($diffLT * 1024)
			$diffLT_KB = [Math]::Round($diffLT_KB, 2)
			Log "$($time.Invoke()) New file is $($diffLT_KB)KB smaller."
		}
		Elseif ($diffLT -lt -1024)
		{
			$diffLT_GB = ($diffLT / 1024)
			$diffLT_GB = [Math]::Round($diffLT_GB, 2)
			Log "$($time.Invoke()) New file is $($diffLT_GB)GB smaller."
		}
		Else
		{
			Log "$($time.Invoke()) New file is $($diffLT)MB smaller."
		}
		
		$script:diskUsage = $script:diskUsage - $diffLT
		
		If ($script:diskUsage -gt -1 -AND $script:diskUsage -lt 1)
		{
			$diskUsage_KB = ($script:diskUsage * 1024)
			$diskUsage_KB = [Math]::Round($diskUsage_KB, 2)
			Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsage_KB)KB"
		}
		Elseif ($script:diskUsage -lt -1024 -OR $script:diskUsage -gt 1024)
		{
			$diskUsage_GB = ($script:diskUsage / 1024)
			$diskUsage_GB = [Math]::Round($diskUsage_GB, 2)
			Log "$($time.Invoke()) Current cumulative storage difference: $($diskUsage_GB)GB"
		}
		Else
		{
			$script:diskUsage = [Math]::Round($script:diskUsage, 2)
			Log "$($time.Invoke()) Current cumulative storage difference: $($script:diskUsage)MB"
		}
	}
	Catch
	{
		Log "$($time.Invoke()) ERROR: $oldFile could not be deleted. Full error below."
		Log $_
	}
}
# If new file is over 25% smaller than the original file, trigger encoding failure
Function FailureDetected
{
	$diffErr = [Math]::Round($fileNew.length - $fileOld.length)/1MB
	$diffErr = [Math]::Round($diffErr, 2)
	Try
	{
		Remove-Item -LiteralPath $newFile -Force -ErrorAction Stop
		Log "$($time.Invoke()) EXCEPTION: New file is over 25% smaller ($($diffErr)MB). $newFile deleted."
		Log "$($time.Invoke()) FAILOVER: Re-encoding $oldFile with Handbrake."
	}
	Catch
	{
		Log "$($time.Invoke()) ERROR: $newFile could not be deleted. Full error below."
		Log $_
	}
}
# Master Encoding function
Function ConvertToNewMP4
{
	param
	(
		[Parameter(Position = 0, mandatory = $true)]
		[ValidateSet("Simple", "Audio", "Video", "Both", "Handbrake")]
		[String]$ConvertType,
		[Switch]$KeepSubs
	)
	
	If ($ConvertType -eq "Handbrake")
	{
		# Handbrake CLI: https://trac.handbrake.fr/wiki/CLIGuide#presets
		# Handbrake arguments
		$hbArgs = @()
		$hbArgs += "-i " #Flag to designate input file
		$hbArgs += "`"$oldFile`"" #Input file
		$hbArgs += "-o " #Flag to designate output file
		$hbArgs += "`"$newFile`"" #Output file
		$hbArgs += "-f " #Format flag
		$hbArgs += "mp4 " #Format value
		$hbArgs += "-a " #Audio channel flag
		$hbArgs += "1,2,3,4,5,6,7,8,9,10 " #Audio channels to scan
		If ($KeepSubs)
		{
			$hbArgs += "--subtitle " #Subtitle channel flag
			$hbArgs += "scan,1,2,3,4,5,6,7,8,9,10 " #Subtitle channels to scan
		}
		$hbArgs += "-e " #Output video codec flag
		$hbArgs += "x264 " #Output using x264
		$hbArgs += "--encoder-preset " #Flag to set encode speed preset
		$hbArgs += "slow " #Encode speed preset
		$hbArgs += "--encoder-profile " #Flag to set encode quality preset
		$hbArgs += "high " #Encode quality preset
		$hbArgs += "--encoder-level " #Profile version to use for encoding
		$hbArgs += "4.1 " #Encode profile value
		$hbArgs += "-q " #Equivalent to CRF in ffmpeg
		$hbArgs += "18 " #CFR value
		$hbArgs += "-E " #Flag to set audio codec
		$hbArgs += "aac " #Use AAC as audio codec
		$hbArgs += "--audio-copy-mask " #Flag to set permitted audio codecs for copying
		$hbArgs += "aac " #Set only AAC as allowed for copying
		$hbArgs += "--verbose=1 " #Flag to set logging level
		$hbArgs += "--decomb " #Flag to set deinterlace video
		$hbArgs += "--loose-anamorphic " #Keep aspect ratio as close as possible to the source videos
		$hbArgs += "--modulus " #Flag to set storage width modulus
		$hbArgs += "2" #Storage width modulus value
		
		$hbCMD = cmd.exe /c "`"$handbrake`" $hbArgs"
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
		# ffmpeg arguments
		$ffArgs = @()
		$ffArgs += "-n " #Do not overwrite output files, and exit immediately if a specified output file already exists.
		$ffArgs += "-fflags " #Allows setting of formal flags
		$ffArgs += "+genpts " #Suppresses pointer warning messages
		$ffArgs += "-i " #Flag to designate input file
		$ffArgs += "`"$oldFile`" " #Input file
		$ffArgs += "-threads " #Flag to set maximum number of threads (CPU) to use
		$ffArgs += "6 " #Maximum number of threads (CPU) to use
        
        If ($setTitle)
        {
            $ffArgs += "-metadata " #Flag to specify key/value pairs for encoding metadata
            $ffArgs += "title=`"$title`" " #Use $title variable as metadata 'Title'
        }

		$ffArgs += "-map " #Flag to use channel mapping
		$ffArgs += "0 " #Channel to map (0 is default)
		$ffArgs += "-c:v " #Video codec flag
		
		#If doing simple or only Audio then just copy video
		If ($ConvertType -eq "Simple" -or $ConvertType -eq "Audio")
		{
			$ffArgs += "copy " #Copy input file codec settings
		}
		
		If ($ConvertType -eq "Video" -or $ConvertType -eq "Both")
		{
			$ffArgs += "libx264 " #Use x264 video codec
			$ffArgs += "-preset " #Video quality preset flag
			$ffArgs += "medium " #Video quality preset
			$ffArgs += "-crf " #Constant rate factor flag
			$ffArgs += "18 " #CRF value
		}
		
		$ffArgs += "-c:a " #Audio codec flag
		
		If ($ConvertType -eq "Simple" -or $ConvertType -eq "Video")
		{
			$ffArgs += "copy " #Copy input file codec settings
		}
		
		If ($ConvertType -eq "Audio" -or $ConvertType -eq "Both")
		{
			$ffArgs += "aac " #Use AAC audio codec
		}
		
		If ($KeepSubs)
		{
			$ffArgs += "-c:s " #Subtitle codec flag
			$ffArgs += "mov_text " #Name of subtitle channel after export
		}
		Else
		{
			$ffArgs += "-sn " #Option to remove any existing subtitles
		}
		$ffArgs += "`"$newFile`"" #Output file
		
		$ffCMD = cmd.exe /c "$ffmpeg $ffArgs"
		
		# Begin ffmpeg operation
		$ffCMD
		Log "$($time.Invoke()) ffmpeg completed"
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
		$diskUsage_KB = ($script:diskUsage * 1024)
		$diskUsage_KB = [Math]::Round($diskUsage_KB, 2)
		Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsage_KB)KB"
	}
	Elseif ($script:diskUsage -lt -1024 -OR $script:diskUsage -gt 1024)
	{
		$diskUsage_GB = ($script:diskUsage / 1024)
		$diskUsage_GB = [Math]::Round($diskUsage_GB, 2)
		Log "$($time.Invoke()) Total cumulative storage difference: $($diskUsage_GB)GB"
	}
	Else
	{
		$script:diskUsage = [Math]::Round($script:diskUsage, 2)
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
		$avgConv = [math]::Round($avgConv, 2)
		Log "Average conversion speed of $($avgConv)x"
	}
	Catch
	{
		Log "No time elapsed."
	}
	
	Log "`n===================================================================================="
}
# Test executables are present in the given paths
Function TestUtility
{
	param
	(
		[parameter(Mandatory = $true)]
		[String]$Path,
		[parameter(Mandatory = $true)]
		[String]$EXEName
	)
	
	$UtilityFullPath = Join-Path $Path $EXEName
	
	If (Test-Path $UtilityFullPath)
	{
		return $UtilityFullPath
	}
	Else
	{
		Write-Output "`n$EXEName could not be found at $($UtilityFullPath)." | Tee-Object -filepath $log -append
		Write-Output "Ensure the path in `$UtilityFullPath is correct." | Tee-Object -filepath $log -append
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
}

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
	$version = "v3.5 RELEASE"
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
	$ffmpeg = TestUtility -Path $ffmpegBinDir -EXEName "ffmpeg.exe"
	$ffprobe = TestUtility -Path $ffmpegBinDir -EXEName "ffprobe.exe"
	$handbrake = TestUtility -Path $handbrakeDir -EXEName "HandBrakeCLI.exe"
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
	$num = Measure-Object -InputObject $fileList
	$fileCount = $num.count
# Initialize disk usage change to 0
	$diskUsage = 0
# Initialize 'video length converted' to 0
	$durTotal = [timespan]::fromseconds(0)

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
        $title = $file.BaseName
		$oldFile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;

		$fileSubDirs = ($file.DirectoryName).Substring($mediaPath.Length, ($file.DirectoryName).Length - $mediaPath.Length);
		If ($useOutPath -eq $True)
		{
			$outPath = $baseOutPath + $fileSubDirs;
			
			IF (-Not (Test-Path $outpath))
			{
				mkdir $outPath
			}
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
		$script:aCodecCMD = Find-Codec -DiscoverType Audio
		$script:vCodecCMD = Find-Codec -DiscoverType Video
		$script:duration = Find-Codec -DiscoverType Duration
			
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
				Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Performing simple container conversion to MP4."
				ConvertToNewMP4 -ConvertType Simple -KeepSubs:$keepSubs
			}
		# Video is already H264, Audio is not AAC
			ElseIf ($vCodecCMD -eq "h264" -AND $aCodecCMD -ne "aac") 
			{
				Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding audio to AAC"
				ConvertToNewMP4 -ConvertType Audio -KeepSubs:$keepSubs
			}	
		# Video is not H264, Audio is already AAC
			ElseIf ($vCodecCMD -ne "h264" -AND $aCodecCMD -eq "aac")
			{
				Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding video to H264."
				ConvertToNewMP4 -ConvertType Video -KeepSubs:$keepSubs
			}
		# Video is not H264, Audio is not AAC
			ElseIf ($vCodecCMD -ne "h264" -AND $aCodecCMD -ne "aac")
			{
				Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding video to H264 and audio to AAC."
				ConvertToNewMP4 -ConvertType Both -KeepSubs:$keepSubs
			}

		# Refresh Plex libraries
			If ($usePlex)
			{
				# Refresh Plex libraries
				Invoke-WebRequest $plexURL -UseBasicParsing
				Log "$($time.Invoke()) Plex libraries refreshed"
			}
            
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
						ConvertToNewMP4 -ConvertType Handbrake -KeepSubs:$keepSubs
								
							# Load files for comparison
								$fileOld = Get-Item $oldFile
								$fileNew = Get-Item $newFile
								
							# If new file is much smaller than old file (likely because the script was aborted re-encode), leave original file alone and print error
								If ($fileNew.length -lt ($fileOld.length * .75))
								{
									$diffErr = [Math]::Round($fileNew.length - $fileOld.length)/1MB
									$diffErr = [Math]::Round($diffErr, 2)
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
