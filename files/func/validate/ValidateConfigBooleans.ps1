#Validate boolean settings from the config file
Function ValidateConfigBooleans {
    $boolArray = 'use_out_path', 'use_set_metadata_title', 'force_stereo_clone', 'keep_subtitles', 'append_log', 'use_ignore_list', 'use_plex', 'collect_garbage'

    ForEach ($value in $boolArray) {
        $curVal = $cfg.$value
        #If the value is not true or false, fail and exit
        If ($curVal -ne 'true' -and $curVal -ne 'false') {
            Log "$($prop.cfg_path) - $value : Expected 'true' or 'false', got $curVal instead."
            Log "Aborting script."
            DeleteLockFile
            Exit
        }
        #If value is true or false, convert from string to bool
        Else {
            $cfg.$value = [System.Convert]::ToBoolean($cfg.($value))
        }
    }
}