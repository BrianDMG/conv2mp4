#Validate boolean settings from the config file
Function ValidateConfigBooleans {
    $boolArray = 'useOutPath', 'setTitle', 'force2chCopy', 'keepSubs', 'appendLog', 'useIgnore', 'usePlex', 'collectGarbage'

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