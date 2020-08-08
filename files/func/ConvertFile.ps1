# Master Encoding function
Function ConvertFile {
    param
    (
        [Parameter(Position = 0, mandatory = $True)]
        [ValidateSet("Simple", "Audio", "Video", "Both", "Handbrake")]
        [String]$ConvertType,
        [Switch]$KeepSubs
    )

    $ffmpeg = Join-Path "$($cfg.ffmpeg_bin_dir)" "ffmpeg.exe"
    $ffprobe = Join-Path "$($cfg.ffmpeg_bin_dir)" "ffprobe.exe"
    $handbrake = Join-Path $cfg.handbrakecli_bin_dir "HandBrakeCLI.exe"

    If ($ConvertType -eq "Handbrake") {
        # Handbrake CLI: https://trac.handbrake.fr/wiki/CLIGuide#presets
        # Handbrake arguments
        $hbArgs = @()
        $hbArgs += "-i " #Flag to designate input file
        $hbArgs += "`"$sourceFile`"" #Input file
        $hbArgs += "-o " #Flag to designate output file
        $hbArgs += "`"$targetFile`"" #Output file
        $hbArgs += "-f " #Format flag
        $hbArgs += "mp4 " #Format value
        $hbArgs += "-a " #Audio channel flag
        $hbArgs += "1,2,3,4,5,6,7,8,9,10 " #Audio channels to scan
        If ($KeepSubs) {
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
        Try {
            $hbCMD
            Log "$($time.Invoke()) Handbrake finished."
        }
        Catch {
            Log "$($time.Invoke()) ERROR: Handbrake has encountered an error."
            Log $_
        }
    }
    Else {
        # ffmpeg arguments
        $ffArgs = @()
        $ffArgs += "-n " #Do not overwrite output files, and exit immediately if a specified output file already exists.
        $ffArgs += "-fflags " #Allows setting of formal flags
        $ffArgs += "+genpts " #Suppresses pointer warning messages
        $ffArgs += "-i " #Flag to designate input file
        $ffArgs += "`"$sourceFile`" " #Input file
        $ffArgs += "-threads " #Flag to set maximum number of threads (CPU) to use
        $ffArgs += "6 " #Maximum number of threads (CPU) to use
        $ffArgs += "-movflags"
        $ffArgs += "+faststart"

        If ($cfg.use_set_metadata_title){

            #Check if it's a TV episode
            If ($title -match 's\d+'){
                $regex = '^(.*?)(S\d+)(E\d+-?\s?E?\d*?)(\D+)(.*$)'
                $unparsedTitle = $title
                $remove = $title | Select-String -Pattern $regex  | ForEach-Object { "$($_.matches.groups[5])" }
                $title = $title -replace [Regex]::Escape("$remove"),''
                $title = $title -replace '\W',' '
                $title = $($title.trim() -replace "\s+"," ")
                $showTitle = $title | Select-String -Pattern $regex  | ForEach-Object { "$($_.matches.groups[1])" }
                $seasonNumber = $title | Select-String -Pattern $regex  | ForEach-Object { "$($_.matches.groups[2])" }
                $seasonNumber = $seasonNumber -replace 's',''
                $episodeNumber = $title | Select-String -Pattern $regex  | ForEach-Object { "$($_.matches.groups[3])" }
                $episodeNumber = $episodeNumber -replace 'e',''
                $episodeNumber = $episodeNumber.trim() -replace '\W','-'
                $episodeTitle = $title | Select-String -Pattern $regex  | ForEach-Object { "$($_.matches.groups[4])" }

                $ffArgs += "-metadata " #Flag to specify key/value pairs for encoding metadata
                $ffArgs += "show=`"$($showTitle.trim())`" " #Use $showTitle variable as metadata 'show'
                $ffArgs += "-metadata " #Flag to specify key/value pairs for encoding metadata
                $ffArgs += "season_number=`"$('{0:d2}' -f [int]$seasonNumber)`" " #Use $seasonNumber variable as metadata 'season_number'
                $ffArgs += "-metadata " #Flag to specify key/value pairs for encoding metadata
                $ffArgs += "episode_id=`"$episodeNumber`" " #Use $episodeNumber variable as metadata 'episode_id'
                $ffArgs += "-metadata " #Flag to specify key/value pairs for encoding metadata
                $ffArgs += "title=`"$($episodeTitle.trim())`" " #Use $episodeTitleitle variable as metadata 'title'
                $ffArgs += "-metadata " #Flag to specify key/value pairs for encoding metadata
                $ffArgs += "description=`"$unparsedTitle`" " #Use $episodeTitleitle variable as metadata 'title'
            }
            #Otherwise it's assumed to be a movie
            Else {
                $regex = '^(.+)((19|20)\d{2})(.*$)'
                $remove = $title | Select-String -Pattern $regex  | ForEach-Object { "$($_.matches.groups[4])" }
                $title = $title -replace [Regex]::Escape("$remove"),''
                $title = $title -replace '\W',' '
                $title = $($title.trim() -replace "\s+"," ")
                $year = $($title.split()[-1])
                $title = $title.SubString(0, $title.LastIndexOf(' '))

                $ffArgs += "-metadata " #Flag to specify key/value pairs for encoding metadata
                $ffArgs += "title=`"$title`" " #Use $title variable as metadata 'title'
                $ffArgs += "-metadata " #Flag to specify key/value pairs for encoding metadata
                $ffArgs += "date=`"$year`" " #Use $year variable as metadata 'date'
            }

            $encodeInformation = "Encoded by conv2mp4-$($prop.platform) v$($prop.version) ($($prop.github_url)) on $($time.Invoke())"
            $ffArgs += "-metadata " #Flag to specify key/value pairs for encoding metadata
            $ffArgs += "comment=`"$encodeInformation`" " #Use $encodingTool variable as metadata 'encoding_tool'
        }

        $ffArgs += "-map " #Flag to use channel mapping
        $ffArgs += "0 " #Channel to map (0 is default)
        $ffArgs += "-c:v " #Video codec flag

        #If doing simple or only Audio then just copy video
        If ($ConvertType -eq "Simple" -or $ConvertType -eq "Audio") {
            $ffArgs += "copy " #Copy input file codec settings
        }

        If ($ConvertType -eq "Video" -or $ConvertType -eq "Both") {
            $ffArgs += "libx264 " #Use x264 video codec
            $ffArgs += "-preset " #Video quality preset flag
            $ffArgs += "medium " #Video quality preset
            $ffArgs += "-crf " #Constant rate factor flag
            $ffArgs += "18 " #CRF value
        }

        $ffArgs += "-c:a " #Audio codec flag

        If ($ConvertType -eq "Simple" -or $ConvertType -eq "Video") {
            $ffArgs += "copy " #Copy input file codec settings
        }

        If ($ConvertType -eq "Audio" -or $ConvertType -eq "Both") {
            $ffArgs += "aac " #Use AAC audio codec
        }

        If ($KeepSubs) {
            $info = & $ffprobe -i $sourceFile 2>&1
            #Detect if bitmap subs exist, and do not keep them if they do. 
            #Resolves error that causes ffmpeg to fail and launch failover
            If (!$($info -Match '(pgssub|dvd_subtitle)')) {
                $ffArgs += "-c:s " #Subtitle codec flag
                $ffArgs += "mov_text " #Name of subtitle channel after export
            }
            Else {
                Log "$($time.Invoke()) Detected bitmap subtitles, not keeping subtitles."
                $ffArgs += "-sn " #Option to remove any existing subtitles
            }
        }
        Else {
            $ffArgs += "-sn " #Option to remove any existing subtitles
        }
        $ffArgs+= "-f mp4 "
        $ffArgs += "`"$targetFile`"" #Output file

        $ffCMD = cmd.exe /c "`"$ffmpeg`" $ffArgs"

        # Begin ffmpeg operation
        $ffCMD
        Write-Output "$($time.Invoke()) ffmpeg completed"
    }
}