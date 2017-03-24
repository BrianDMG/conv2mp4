<#======================================================================================================================
conv2mp4-ps - https://github.com/BrianDMG/conv2mp4-ps v1.9 BETA

This Powershell script will recursively search through a user-defined file path and convert all videos of user-specified 
filetypes to MP4 with H264 video and AAC audio using ffmpeg. If a conversion failure is detected, the script re-encodes
the file with HandbrakeCLI. Upon successful encoding, Plex libraries are refreshed and source file is deleted. 
The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server.
========================================================================================================================
ffmpeg : https://ffmpeg.org/download.html
handbrakecli : https://handbrake.fr/downloads.php #>
<#----------------------------------------------------------------------------------------------------------------------
User-defined variables
------------------------------------------------------------------------------------------------------------------------
$mediaPath = the path to the media you want to convert (no trailing "\")
NOTE: For network shares, use UNC path if you plan on running this script as a scheduled task.
----- If running manually and using a mapped drive, you must run "net use z: \\server\share /persistent:yes" as the user y
----- you're going to run the script as (generally Administrator) prior to running the script.
$fileTypes = the extensions of the files you want to convert in the format "*.ex1", "*.ex2". Do NOT add .mp4!
$logPath = path you want the log file to save to. defaults to your desktop. (no trailing "\")
$logName = the filename of the log file
$plexIP = the IP address and port of your Plex server (for the purpose of refreshing its libraries)
$plexToken = your Plex server's token (for the purpose of refreshing its libraries).
NOTE: Plex server token - See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token
----- Plex server token is also easy to retrieve with PlexPy, Ombi, Couchpotato, or SickRage 
$ffmpegBinDir = path to ffmpeg bin folder (no trailing "\"). This is the directory containing ffmpeg.exe and ffprobe.exe 
$handbrake = path to Handbrake directory (no trailing "\"). This is the directory containing HandBrakeCLI.exe
$script:garbage = the extensions of the files you want to delete in the format "*.ex1", "*.ex2"
-----------------------------------------------------------------------------------------------------------------------#>
$mediaPath = " "
$fileTypes = "*.mkv", "*.avi", "*.flv", "*.mpeg", "*.ts" #Do NOT add .mp4!
$logPath = "C:\Users\$env:username\Desktop"
$logName= "conv2mp4-ps.log"
$plexIP = 'plexip:32400'
$plexToken = 'plextoken'
$ffmpegBinDir = "C:\ffmpeg\bin"
$handbrakeDir = "C:\Program Files\HandBrake"
$script:garbage = "*.nfo"

<#----------------------------------------------------------------------------------
Static variables (do not change)
----------------------------------------------------------------------------------#>
# Print initial wait notice to console
	Write-Host "`nBuilding file list, please wait. This may take a while, especially for large libraries.`n"
# Get current time to store as start time for script
	$script:scriptDurStart = (Get-Date -format "HH:mm:ss")
# Build file paths to executables and log
	$ffmpeg = Join-Path "$ffmpegBinDir" "ffmpeg.exe"
	$ffprobe = Join-Path "$ffmpegBinDir" "ffprobe.exe"
	$handbrake = Join-Path "$handbrakeDir" "HandBrakeCLI.exe"
	$log = Join-Path "$logPath" "$logName"
# Setup for file list loop
	$mPath = Get-Item -Path $mediaPath
	$fileList = Get-ChildItem "$($mPath.FullName)\*" -i $fileTypes -recurse
	$num = $fileList | measure
	$fileCount = $num.count
# Time and format used for timestamps in the log
	$time = {Get-Date -format "MM/dd/yy HH:mm:ss"}
# Initialize disk usage change to 0
	$diskUsage = 0
# Initialize 'video length converted' to 0
	$durTotal = [timespan]::fromseconds(0)

<#----------------------------------------------------------------------------------
Functions (do not change)
----------------------------------------------------------------------------------#>
# Logging and console output
	Function Log
	{
	   Param ([string]$logString)
	   Write-Output $logString | Tee -filepath $log -append
	}
# List files in the queue in the log
	Function ListFiles
	{			 
		Log "There are $fileCount file(s) are in the queue:`n"
		
		$i = 0
		$num = 0
		ForEach ($file in $fileList)
		{
			$i++;
			
			$num = $num +1
			Log "$($num). $file"
		}
		Log ""
	}
# If new and old files are the same size
	Function IfSame
	{
		$errOccured = $False
			
			try
			{
				Remove-Item $oldFile -Force -ErrorAction Stop
				Log "$($time.Invoke()) Same file size."
				Log "$($time.Invoke()) $oldFile deleted."
			}	
			catch
			{	
				$errOccured = $True 
				Log "$($time.Invoke()) ERROR: $oldFile could not be deleted. Full error below."
				Log $_
			}				
	}
# If new file is larger than old file
	Function IfLarger
       {
           $errOccured = $False
           $diffGT = [Math]::Round($fileNew.length-$fileOld.length)/1MB -as [int]
 
			try
            {
                Remove-Item $oldFile -Force -ErrorAction Stop
                Log "$($time.Invoke()) New file is $($diffGT)MB larger."
                Log "$($time.Invoke()) $oldFile deleted."
				$script:diskUsage = $script:diskUsage + $diffGT
                Log "$($time.Invoke()) Current cumulative storage difference: $script:diskUsage MB"
            }           
            catch
            {
                $errOccured = $True
                Log "$($time.Invoke()) ERROR: $oldFile could not be deleted. Full error below."
                Log $_
            }
       }
# If new file is smaller than old file
	Function IfSmaller
	{
		$errOccured = $False
		$diffLT = [Math]::Round($fileOld.length-$fileNew.length)/1MB -as [int]
			
			try
			{
				Remove-Item $oldFile -Force -ErrorAction Stop
				Log "$($time.Invoke()) New file is $($diffLT)MB smaller."
				Log "$($time.Invoke()) $oldFile deleted."
				$script:diskUsage = $script:diskUsage - $diffLT
				Log "$($time.Invoke()) Current cumulative disk usage difference: $script:diskUsage MB"
			}
			catch
			{
				$errOccured = $True
				Log "$($time.Invoke()) ERROR: $oldFile could not be deleted. Full error below."
				Log $_
			}
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
			$script:duration = "$($durTemp.hours):$($durTemp.minutes):$($durTemp.seconds)"
	}
# If a file video codec is already H264 and audio codec is already AAC, use these arguments
	Function SimpleConvert	
	{	
		Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Performing simple container conversion to MP4."
		
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
# If a file video codec is already H264, but audio codec is not AAC, use these arguments
	Function EncodeAudio
	{
		Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding audio to AAC"
			
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
# If a file video codec is not H264, and audio codec is already AAC, use these arguments
	Function EncodeVideo
	{
		Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding video to H264."
	
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
# If a file video codec is not H264, and audio codec is not AAC, use these arguments
	Function EncodeBoth
	{	
		Log "$($time.Invoke()) Video: $($script:vCodecCMD.ToUpper()), Audio: $($script:aCodecCMD.ToUpper()). Encoding video to H264 and audio to AAC."
	
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
# Delete garbage files
	Function GarbageCollection
	{
		Log "`nGarbage Collection: The following additional file(s) were deleted:"
		Get-ChildItem "$($mPath.FullName)\*" -i $script:garbage -recurse | foreach ($_) {Log $_.fullname}
		Get-ChildItem "$($mPath.FullName)\*" -i $script:garbage -recurse | foreach ($_) {Remove-Item $_.fullname -Force}
	}
# Log various session statistics 
	Function FinalStatistics
	{
		Log "`n===================================================================================="
		#Print total session disk usage changes
			$diskUsageGB = ($script:diskUsage/1024)
			Log "`nTotal session disk usage change: $($diskUsageGB)GB"
		#Do some time math to get total script runtime
			$script:scriptDurTemp = new-timespan $script:scriptDurStart $(get-date -format "HH:mm:ss")
			$script:scriptDurTotal = "$($script:scriptDurTemp.hours):$($script:scriptDurTemp.minutes):$($script:scriptDurTemp.seconds)"
			Log "`n$script:durTotal of video processed in $script:scriptDurTotal"
		#Do some math/rounding to get session average conversion speed	
			$script:avgConv = $script:durTicksTotal / $script:scriptDurTemp.Ticks
			$script:avgConv = [math]::Round($script:avgConv,2)
			Log "Average conversion speed of $($script:avgConv)x"
		Log "`n===================================================================================="
	}
<#----------------------------------------------------------------------------------
Preperation 
----------------------------------------------------------------------------------#>
	# Set z: shared drive
		#net use z: \\192.168.82.82\nas /persistent:yes
	# Clear log contents
		Clear-Content $log
	
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
		$newFile = $file.DirectoryName + "\" + $file.BaseName + ".mp4";
		$plexURL = "http://$plexIP/library/sections/all/refresh?X-Plex-Token=$plexToken"
		$progress = ($i / $fileCount) * 100
		$progress = [Math]::Round($progress,2)
		
		Log "------------------------------------------------------------------------------------"
		Log "$($time.Invoke()) Processing - $oldFile"
		Log "$($time.Invoke()) File $i of $fileCount - Total queue $progress%"

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
			Invoke-WebRequest $plexURL 
			Log "$($time.Invoke()) Plex libraries refreshed"
					
		<#----------------------------------------------------------------------------------
		Begin file comparison between old file and new file to determine conversion success
		-----------------------------------------------------------------------------------#>
		# Load files for comparison
			$fileOld = Get-Item $oldFile
			$fileNew = Get-Item $newFile
			$confDelOld = Test-Path $oldFile		
			$confDelNew = Test-Path $newFile
				
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
					$errOccured = $False
					$diffErr = [Math]::Round($fileNew.length-$fileOld.length)/1MB -as [int]
					
					try
					{
							Remove-Item $newFile -Force -ErrorAction Stop
							Log "$($time.Invoke()) EXCEPTION: New file is over 25% smaller ($($diffErr)MB). $newFile deleted."
							Log "$($time.Invoke()) FAILOVER: Re-encoding $oldFile with Handbrake."
					}
					catch
					{
						$errOccured = $True
						Log "$($time.Invoke()) ERROR: $newFile could not be deleted. Full error below."
						Log $_
					}
					
						<#----------------------------------------------------------------------------------
						Begin Handbrake encode (lossy)
						----------------------------------------------------------------------------------#>
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
							$errOccured = $False
							try 
							{
								$hbCMD
								Log "$($time.Invoke()) Handbrake finished."
							}
							catch
							{
								$errOccured = $True
								Log "$($time.Invoke()) ERROR: Handbrake has encountered an error."
								Log $_
							}
								# If new file is much smaller than old file (likely because the script was aborted re-encode), leave original file alone and print error
									If ($fileNew.length -lt ($fileOld.length * .75))
									{
									Log "ERROR: New file was too small. Deleted $newFile and retained $oldFile."
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
	} # End foreach loop
	
<#----------------------------------------------------------------------------------
Wrap-up
-----------------------------------------------------------------------------------#>
FinalStatistics
GarbageCollection
Log "`nFinished"
Exit
