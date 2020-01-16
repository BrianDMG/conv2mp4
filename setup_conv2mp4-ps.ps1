<#======================================================================================================================
setup_conv2mp4-ps.ps1 v3.0-SNAPSHOT04122017

Executing this script stores variables as defined by the user to cfg_conv2mp4-ps.ps1. 
This script also tests user input to ensure that paths, format, and IPs are valid/reachable.
========================================================================================================================

Dependencies:

PowerShell 3.0+
ffmpeg : https://ffmpeg.org/download.html
handbrakecli : https://handbrake.fr/downloads.php
------------------------------------------------------------------------------------------------------------------------#>

<#------------------------------------------------------------------------------------------------------------------------
Preparation
------------------------------------------------------------------------------------------------------------------------#>
$version = "v3.2"
# Print version number to console
	Write-Host "`n------------------------------------------------------------------------------------"
	Write-Host "conv2mp4-ps1 Configuration Utility $version"
# Join script directory and config file
	$cfgFile = Join-Path "$PSScriptRoot" "cfg_conv2mp4-ps.ps1"	
	
# Make a backup of the current $cfgFile
    Copy $cfgFile "$cfgFile.bk"
    Write-Host "`nCreated a backup of $cfgFile" -Foregroundcolor Green
# Clear contents of $cfgFile after making a backup
    Clear-Content $cfgFile

# Print version and comments to $cfgFile
Write-Output "<#======================================================================================================================
cfg_conv2mp4-ps $version - https://github.com/BrianDMG/conv2mp4-ps

***THIS IS A BETA - DO NOT USE IN PRODUCTION***

This script stores user-defined variables retrieved from setup_conv2mp4.ps1. 
The values in this file can also be manually edited.
========================================================================================================================

Dependencies:

PowerShell 3.0+
ffmpeg : https://ffmpeg.org/download.html
handbrakecli : https://handbrake.fr/downloads.php
------------------------------------------------------------------------------------------------------------------------#>

<#----------------------------------------------------------------------------------------------------------------------
User-defined variables
------------------------------------------------------------------------------------------------------------------------
`$mediaPath = the path to the media you want to convert (no trailing '\')
NOTE: For network shares, use UNC path if you plan on running this script as a scheduled task.
----- If running manually and using a mapped drive, you must run 'net use z: \\server\share /persistent:yes' as the user
----- you're going to run the script as (generally Administrator) prior to running the script.
`$fileTypes = the extensions of the files you want to convert in the format '*.ex1', '*.ex2'. Do NOT add .mp4!
`$logPath = path you want the log file to save to. defaults to your desktop. (no trailing '\')
`$logName = the filename of the log file
`$plexIP = the IP address and port of your Plex server (for the purpose of refreshing its libraries)
`$plexToken = your Plex server's token (for the purpose of refreshing its libraries).
NOTE: Plex server token - See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token
----- Plex server token is also easy to retrieve with PlexPy, Ombi, Couchpotato, or SickRage 
`$ffmpegBinDir = path to ffmpeg bin folder (no trailing '\'). This is the directory containing ffmpeg.exe and ffprobe.exe 
`$handbrakeDir = path to Handbrake directory (no trailing '\'). This is the directory containing HandBrakeCLI.exe
`$script:garbage = the extensions of the files you want to delete in the format '*.ex1', '*.ex2'
`$appendLog = $False will clear log at the beginning of every session, $True will append new session log to old session log 
-----------------------------------------------------------------------------------------------------------------------#>" | Out-File $cfgFile -Append

<#------------------------------------------------------------------------------------------------------------------------
Functions
------------------------------------------------------------------------------------------------------------------------#>
# Media path functions

	Function TestMediaPath
	{
		Do
		{
			Write-Host "Media path not found, try again." -ForegroundColor Red
			$script:mediaPath = Read-Host "Media path: "
			$testMediaPath = Test-Path $script:mediaPath
		}
		Until ($testMediaPath -eq $True)
	}

#----------------------------------------------------------------------------------------------------------------	

	Function TestMediaTrails
	{
		 Do 
		{
		   Write-Host "Do not include a trailing `"\`" or `"/`" at the end of the path." -ForegroundColor Red
		   $script:mediaPath = Read-Host "Media path: "
		}
		Until ($script:mediaPath -Match "\D*[^\\]$" -OR $script:mediaPath -Match "\D*[^\\]$")    
	}

#----------------------------------------------------------------------------------------------------------------
	
	Function GetMediaPath
	{
		$script:mediaPath = Read-Host "Media path: "
		$testMediaPath = Test-Path $script:mediaPath  

		If ($script:mediaPath -Match "\D*[\\]$" -OR $script:mediaPath -Match "\D*[\/]$")
		{
			TestMediaTrails
			TestMediaPath
		}
		Elseif ($testMediaPath -eq $False)
		{
			TestMediaPath
			TestMediaTrails
		}
		
		Write-Host "`nMedia path ($mediaPath) validated." -ForegroundColor Green
		Write-Output "`$mediaPath = `"$mediaPath`"" | out-file -file $cfgFile -append      
	}

#////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#Conversion file types

	Function GetConvertedFileTypes
	{
		$yesNo = "y"
			[array]$fileTypesArr = $Null
			Do
			{
				$defaultValue = "mkv"
				If (($fileType = Read-Host "File type (or enter to accept default value [$defaultValue]: ") -eq '')
				{
					$fileType = $defaultValue
				}
				else
				{
					$fileType
				}
				
				[array]$fileTypesArr += "`"`*`.$fileType`""
				$yesNo = Read-Host "Add more file types? (Y/N): "
				
						if ($yesNo -ne "y" -AND $yesNo -ne "n")
						{
							do 
							{
								Write-Host "You must enter either `"y`" or `"n`"." -ForegroundColor Red
								$yesNo = Read-Host "Add more file types? (Y/N): "
							}
							until ($yesNo -eq "y" -OR $yesNo -eq "n")
						}
						else
						{
						}
			}
			Until ($yesNo -eq "N" -OR $yesNo -eq "n")
			
			$script:fileTypes = $fileTypesArr -join ', '
			Write-Host "`nFile types to be converted: $fileTypes" -ForegroundColor Green
			Write-Output "`$fileTypes = $fileTypes" | Out-File -File $cfgFile -Append
	}
#////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#Log functions

	Function TestLogPath
	{
		Do
		{
			Write-Host "Log path not found, try again." -ForegroundColor Red
			$script:logPath = Read-Host "Log path: "
			$testLogPath = Test-Path $script:logPath
		}
		Until ($testLogPath -eq $True)
	}
	
#----------------------------------------------------------------------------------------------------------------
	
	Function TestLogTrails
	{
		Do 
		{
		   Write-Host "Do not include a trailing `"\`" or `"/`" at the end of the path." -ForegroundColor Red
		   $script:logPath = Read-Host "Log path: "
		}
		Until ($script:logPath -Match "\D*[^\\]$" -OR $script:logPath -Match "\D*[^\\]$")    
	}
	
#----------------------------------------------------------------------------------------------------------------
	
	Function GetLogPath
	{
		$defaultValue = $PSScriptRoot
		If(($script:logPath = Read-Host "Log path (or press enter to accept default [$defaultValue]: ") -eq '')
		{
			$script:logPath = $defaultValue
		}
		Else
		{
			$script:logPath
		}
		$testLogPath = Test-Path $script:logPath  

		If ($script:logPath -Match "\D*[\\]$" -OR $script:logPath -Match "\D*[\/]$")
		{
			TestLogTrails
			TestLogPath
		}
		Elseif ($testLogPath -eq $False)
		{
			TestLogPath
			TestLogTrails
		}
		
		Write-Host "`nLog path ($script:logPath) verified." -ForegroundColor Green
		Write-Output "`$logPath = `"$script:logPath`"" | out-file -file $cfgFile -append
	}

#----------------------------------------------------------------------------------------------------------------	

	Function TestLogName
	{
		Do
		{
		   Write-Host "Log file name cannot contain `"\`" or `"/`"." -ForegroundColor Red
		   $script:logPath = Read-Host "Log path: "
		}
		Until ($script:logPath -Match "[a-zA-Z0-9\-\.]*")
	}

#----------------------------------------------------------------------------------------------------------------

	Function GetLogName
	{
		$defaultValue = "conv2mp4-ps.log"
		If (($script:logName = Read-Host "Press enter to accept default value [$defaultValue]: ") -eq '')
		{
			$script:logName = $defaultValue
		}
		Else
		{
			$script:logName
		}
		
		If ($script:logName -notmatch "[a-zA-Z0-9\-\.]*")
		{
			TestLogName
		}
		
		Write-Host "`nLog will be named $script:logName`.`n" -ForegroundColor Green
		Write-Output "`$logName = `"$script:logName`"" | out-file -file $cfgFile -append
	}

#////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#Plex functions

	Function TestPlexIP
	{
		Do 
		{
			Write-Host "That does not appear to be a valid IPv4 address. Try again." -ForegroundColor Red
			$script:plexIP = Read-Host "Plex Server IP: "
		}
		Until ($script:plexIP -match "\b(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}\b")
	}

#----------------------------------------------------------------------------------------------------------------

	Function TestPlexConnection
	{
		Do
		{
			Write-Host "Cannot ping this server. Try again." -ForegroundColor Red
			$script:plexIP = Read-Host "Plex server IP: "
			$testPlexConn = Test-Connection -ComputerName $script:plexIP -Quiet -Count 1
		}
		Until ($testPlexConn -eq $True)
	}

#----------------------------------------------------------------------------------------------------------------

	Function GetPlexIP
	{
		$script:plexIP = Read-Host "Plex Server IP: "
		$testPlexConn = Test-Connection -ComputerName $script:plexIP -Quiet -Count 1
		If ($script:plexIP -notmatch "\b(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}\b")
		{
			TestPlexIP
			$testPlexConn = Test-Connection -ComputerName $script:plexIP -Quiet -Count 1
			If ($testPlexConn -eq $False)
			{
				TestPlexConnection
			}
		}
		
		Elseif ($testPlexConn -eq $False)
		{
			TestPlexConnection
			If ($script:plexIP -notmatch "\b(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}\b")
			{
				TestPlexIP
			}
		}

		Write-Host "`nPlex server IP address: $plexIP`:32400." -ForegroundColor Green
		Write-Output "`$plexIP = `"$plexIP`:32400`"" | out-file -file $cfgFile -append
	}

#----------------------------------------------------------------------------------------------------------------

	Function GetPlexToken
	{
		$script:plexToken = Read-Host "Plex server token: "
		Write-Host "`nPlex server token is $plexToken." -ForegroundColor Green
		Write-Output "`$plexToken = `"$plexToken`"" | out-file -file $cfgFile -append
	}

#////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ffmpeg functions		

	Function TestffmpegPath
	{
		Do
		{
			Write-Host "ffmpeg path not found, try again." -ForegroundColor Red
			$script:ffmpegBinDir = Read-Host "ffmpeg path: "
			$testffmpegPath = Test-Path $script:ffmpegBinDir
		}
		Until ($testffmpegPath -eq $True)
	}

#----------------------------------------------------------------------------------------------------------------

	Function TestffmpegTrails
	{
		 Do 
		{
		   Write-Host "Do not include a trailing `"\`" or `"/`" at the end of the path." -ForegroundColor Red
		   $script:ffmpegBinDir = Read-Host "ffmpeg path: "
		}
		Until ($script:ffmpegBinDir -Match "\D*[^\\]$" -OR $script:ffmpegBinDir -Match "\D*[^\\]$")    
	}

#----------------------------------------------------------------------------------------------------------------

	Function TestffmpegExe
	{
		Do 
		{
			Write-Host "Do not include the executable itself, only the path." -ForegroundColor Red
			$script:ffmpegBinDir = Read-Host "ffmpeg path: "
		}
		Until ($script:ffmpegBinDir -notlike "*.*")
	}

#----------------------------------------------------------------------------------------------------------------

	Function GetFFMPEGPath
	{
		$defaultValue = "C:\ffmpeg\bin"
		If (($script:ffmpegBinDir = Read-Host "ffmpeg path (or enter to accept default [$defaultValue]: ") -eq '')
		{
			$script:ffmpegBinDir = $defaultValue
		}
		Else
		{
			$script:ffmpegBinDir
		}

		$testffmpegPath = Test-Path $script:ffmpegBinDir  

		If ($script:ffmpegBinDir -Match "\D*[\\]$" -OR $script:ffmpegBinDir -Match "\D*[\/]$")
		{
			TestffmpegTrails
			$testffmpegPath = Test-Path $script:ffmpegBinDir
			If ($testffmpegPath -eq $False)
			{
				TestffmpegPath
			}
			Elseif ($script:ffmpegBinDir -Like "*.*")
			{
				TestffmpegExe
			}
		}
		Elseif ($testffmpegPath -eq $False)
		{
			TestffmpegPath
			If ($script:ffmpegBinDir -Match "\D*[\\]$" -OR $script:ffmpegBinDir -Match "\D*[\/]$")
			{
				TestffmpegTrails
			}
			Elseif ($script:ffmpegBinDir -Like "*.*")
			{
				TestffmpegExe
			}
		}
		Elseif ($script:ffmpegBinDir -Like "*.*")
		   {
			TestffmpegExe
			If ($script:ffmpegBinDir -Match "\D*[\\]$" -OR $script:ffmpegBinDir -Match "\D*[\/]$")
			{
				TestffmpegTrails
			}
			$testffmpegPath = Test-Path $script:ffmpegBinDir
			Elseif ($testffmpegPath -eq $False)
			{
				TestffmpegPath
			}
		}
			
		Write-Host "`nffmpeg path ($script:ffmpegBinDir) validated." -ForegroundColor Green
		Write-Output "`$ffmpegBinDir = `"$script:ffmpegBinDir`"" | out-file -file $cfgFile -append   
	}

#////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
#Handbrake functions	

	Function TestHandbrakePath
	{
		Do
		{
			Write-Host "Handbrake path not found, try again." -ForegroundColor Red
			$script:handbrakeDir = Read-Host "Handbrake path: "
			$testHandbrakePath = Test-Path $script:handbrakeDir
		}
		Until ($testHandbrakePath -eq $True)
	}

#----------------------------------------------------------------------------------------------------------------

	Function TestHandbrakeTrails
	{
		 Do 
		{
		   Write-Host "Do not include a trailing `"\`" or `"/`" at the end of the path." -ForegroundColor Red
		   $script:handbrakeDir = Read-Host "Handbrake path: "
		}
		Until ($script:handbrakeDir -Match "\D*[^\\]$" -OR $script:handbrakeDir -Match "\D*[^\\]$")    
	}

#----------------------------------------------------------------------------------------------------------------

	Function TestHandbrakeExe
	{
		Do 
		{
			Write-Host "Do not include the executable itself, only the path." -ForegroundColor Red
			$script:handbrakeDir = Read-Host "Handbrake path: "
		}
		Until ($script:handbrakeDir -notlike "*.*")
	}

#----------------------------------------------------------------------------------------------------------------

	Function GetHandbrakePath
	{
		$defaultValue = "C:\program files\handbrake"
		If (($script:handbrakeDir = Read-Host "Handbrake path (or press enter for default [$defaultValue]): ") -eq '')
		{
			$script:handbrakeDir = $defaultValue
		}
		Else
		{
			$script:handbrakeDir
		}
		
		$testHandbrakePath = Test-Path $script:handbrakeDir  

		If ($script:handbrakeDir -Match "\D*[\\]$" -OR $script:handbrakeDir -Match "\D*[\/]$")
		{
			TestHandbrakeTrails
			$testHandbrakePath = Test-Path $script:handbrakeDir
			If ($testHandbrakePath -eq $False)
			{
				TestHandbrakePath
			}
			Elseif ($script:handbrakeDir -Like "*.*")
			{
				TestHandbrakeExe
			}
		}
		Elseif ($testHandbrakePath -eq $False)
		{
			TestHandbrakePath
			If ($script:handbrakeDir -Match "\D*[\\]$" -OR $script:handbrakeDir -Match "\D*[\/]$")
			{
				TestHandbrakeTrails
			}
			Elseif ($script:handbrakeDir -Like "*.*")
			{
				TestHandbrakeExe
			}
		}
		Elseif ($script:handbrakeDir -Like "*.*")
		   {
			TestHandbrakeExe
			If ($script:handbrakeDir -Match "\D*[\\]$" -OR $script:handbrakeDir -Match "\D*[\/]$")
			{
				TestHandbrakeTrails
			}
			$testHandbrakePath = Test-Path $script:handbrakeDir
			Elseif ($testHandbrakePath -eq $False)
			{
				TestHandbrakePath
			}
		}            
								
		Write-Host "`nHandbrake path ($script:handbrakeDir) validated." -ForegroundColor Green
		Write-Output "`$handbrakeDir = `"$script:handbrakeDir`"" | out-file -file $cfgFile -append
	}
	
#////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
#Garbage collection functions

	Function GarbageEnabled
	{
		[array]$script:garbageTypesArr = $Null
		Do
		{
			Write-Host "> Enter the extensions of the files you want to delete. No `".`" needed.`n" -ForegroundColor Yellow
			$script:garbageType = Read-Host "File type: "
			[array]$script:garbageTypesArr += "`"`*`.$script:garbageType`""
			$yesNo = Read-Host "Add more file types? (Y/N): "
			if ($yesNo -ne "y" -AND $yesNo -ne "n")
			{
				do 
				{
					Write-Host "You must enter either `"y`" or `"n`"." -ForegroundColor Red
					$yesNo = Read-Host "Add more file types? (Y/N): "
				}
				until ($yesNo -eq "y" -OR $yesNo -eq "n")
			}
			else
			{
			}            
		}
		Until ($yesNo -eq "N" -OR $yesNo -eq "n")
		
			$script:garbageTypes = $script:garbageTypesArr -join ', '
				
				$script:garbageEnabled = "enabled"
				Write-Host "`nGarbage collection enabled for $script:garbageTypes" -ForegroundColor Green
				Write-Output "`$script:garbage = $script:garbageTypes" | Out-File -File $cfgFile -Append
	}

#----------------------------------------------------------------------------------------------------------------

	Function GarbageDisabled
	{
		Write-Output '$script:garbage = "*.garbagecollectiondsiabled"' | Out-File -File $cfgFile -Append
		$script:garbageEnabled = "disabled"
		Write-Host "`nGarbage collection disabled." -ForegroundColor Green

	}

#----------------------------------------------------------------------------------------------------------------

	Function GarbageCollection
	{
		$script:enableGarbage = Read-Host "Would you like to enable garbage collection? (Y/N): "
			If ($script:enableGarbage -eq "N" -OR $script:enableGarbage -eq "n")
			{
				GarbageDisabled
			}
			Else
			{
				GarbageEnabled            
			}
	}

#////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#Log functions

	Function LogAppendDisable
	{
		Write-Host "`nLog appending disabled." -ForegroundColor Green
		$script:logEnabled = "disabled"
		Write-Output "`$appendLog = `$False" | Out-File $cfgFile -Append
	}

#----------------------------------------------------------------------------------------------------------------

	Function LogAppendEnable
	{
		Write-Host "`nLog appending enabled." -ForegroundColor Green
		$script:logEnabled = "enabled"
		Write-Output "`$appendLog = `$True" | Out-File $cfgFile -Append
	}

#----------------------------------------------------------------------------------------------------------------

	Function LogAppend
	{
			$script:enableLogAppend = Read-Host "Would you like to enable log appending? (Y/N): "
			If ($enableLogAppend -eq "N" -OR $enableLogAppend -eq "n")
			{
				LogAppendDisable
			}
			Else
			{
				LogAppendEnable
			}
	}
	
#////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
#Verification function	

	Function FinalVerification
	{
		Write-Host "Media path: $mediaPath" -ForegroundColor Green
		Write-Host "File types to be converted: $script:fileTypes" -ForegroundColor Green
		Write-Host "Log path: $script:logPath" -ForegroundColor Green
		Write-Host "Log name: $script:logName" -ForegroundColor Green
		Write-Host "Plex server IP address: $script:plexIP`:32400" -ForegroundColor Green
		Write-Host "Plex server token: $script:plexToken" -ForegroundColor Green
		Write-Host "ffmpeg path: $script:ffmpegBinDir" -ForegroundColor Green
		write-host "Handbrake path: $script:handbrakeDir" -ForegroundColor Green
		If ($script:garbageEnabled -eq "enabled")
		{
			Write-Host "Garbage collection: $script:garbageEnabled for $script:garbageTypes" -ForegroundColor Green
		}
		Else
		{
			Write-Host "Garbage collection: $script:garbageEnabled" -ForegroundColor Green
		}
		If ($script:logEnabled -eq "enabled")
		{
			Write-Host "Log appending: $script:logEnabled" -ForegroundColor Green
		}
		Else
		{
			Write-Host "Log appending: $script:logEnabled" -ForegroundColor Green
		}
	}
	
<#------------------------------------------------------------------------------------------------------------------------
Data collection
------------------------------------------------------------------------------------------------------------------------#>
#Media path entry and testing
    Write-Host "`n------------------------------------------------------------------------------------"
    Write-Host "MEDIA PATH`n"
    Write-Host "The path to the media you want to convert`n"
    Write-Host "> No trailing `"\`" or `"/`"" -ForegroundColor Yellow
    Write-Host "> For network shares, use UNC path if you plan on running this script as a scheduled task." -ForegroundColor Yellow
    Write-Host "> If running manually and using a mapped drive, you must run `"net use z: \\server\share /persistent:yes`"" -ForegroundColor Yellow
    Write-Host ">> as the user you're going to run the script as (generally Administrator) prior to running the script." -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------`n"          
    
	GetMediaPath
	
# Get desired file types to be converted
    Write-Host "`n------------------------------------------------------------------------------------"
    Write-Host "FILE TYPES TO CONVERT`n"
    Write-Host "Enter the extensions of the files you want to convert."
    Write-Host "> No `".`" needed." -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------`n"
        
    GetConvertedFileTypes    
        
# Get log path
    Write-Host "`n------------------------------------------------------------------------------------"
    Write-Host "LOG PATH`n"
    Write-Host "Path where the log file will save to."
    Write-Host "No trailing `"\`"." -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------`n"
			
	GetLogPath
	
# Get log filename
    Write-Host "`n------------------------------------------------------------------------------------"
    Write-Host "LOG FILE NAME`n"
    Write-Host "File name of the log file."
    Write-Host "Include file extension if one is desired" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------`n"
    
	GetLogName

# Get Plex IP Address
    Write-Host "`n------------------------------------------------------------------------------------"
    Write-HOst "PLEX SERVER IP`n"
    Write-Host "Your Plex server's IP address."
    Write-Host "------------------------------------------------------------------------------------`n"
    
	GetPlexIP

#Get Plex token
    Write-Host "`n------------------------------------------------------------------------------------"
    Write-Host "PLEX SERVER TOKEN`n"
    Write-Host "> This is only used for the purpose of refreshing your Plex libraries once file finishes." -ForegroundColor Yellow
    Write-Host "> See https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token" -ForegroundColor Yellow
    Write-Host "> Token is also easy to retrieve with PlexPy, Ombi, Couchpotato, or SickRage." -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------`n"  
    
	GetPlexToken

#Get ffmpeg path
    Write-Host "`n------------------------------------------------------------------------------------"
    Write-Host "PATH TO FFMPEG BINARY`n"
    Write-Host "> Do not include a trailing `"\`" or `"/`" at the end of the path" -ForegroundColor Yellow
    Write-Host "> Do not include the executable name itself, only the path" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------`n"
                     
    GetFFMPEGPath    

#Get HandbrakeCLI path
    Write-Host "`n------------------------------------------------------------------------------------"
    Write-Host "PATH TO HANDBRAKECLI BINARY`n"
    Write-Host "> Do not include a trailing `"\`" or `"/`" at the end of the path" -ForegroundColor Yellow
    Write-Host "> Do not include the executable name itself, only the path" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------`n"
        
    GetHandbrakePath                        

# Get garbage collection settings
    Write-Host "`n------------------------------------------------------------------------------------"
    Write-Host "GARBAGE COLLECTION`n"
    Write-Host "> If enabled, this feature deletes files of the specified type(s) from the media path." -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------`n"
    
	GarbageCollection

# Enable / disable log append
    Write-Host "`n------------------------------------------------------------------------------------"
    Write-Host "LOG APPEND`n"
    Write-Host "> If enabled, new session log will be appended to previous session log." -ForegroundColor Yellow
    Write-Host "> If disabled, new session log will overwite old session log." -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------`n"
    
	LogAppend

# Final rundown
	Write-Host "`n------------------------------------------------------------------------------------"
    Write-Host "FINAL VERIFICATION"
    Write-Host "------------------------------------------------------------------------------------`n"
    
	FinalVerification

<#------------------------------------------------------------------------------------------------------------------------
Wrap-up
------------------------------------------------------------------------------------------------------------------------#>
Write-Host "`nFinished"
Exit