#Validate boolean settings from the config file
Function Confirm-ConfigBooleans {

  $boolArray = 'use_out_path', 'use_set_metadata_title', 'force_stereo_clone', 'keep', 'use_ignore_list', 'enable', 'enable'

  ForEach ($value in $boolArray) {
    $curVal = $cfg.$value
    #If the value is not true or false, fail and exit
    If ($curVal -ne 'true' -and $curVal -ne 'false') {
      Add-Log "$($prop.paths.cfg) - $value : Expected 'true' or 'false', got $curVal instead."
      Add-Log "Aborting script."
      Remove-LockFile
      Exit
    }
    #If value is true or false, convert from string to bool
    Else {
      $cfg.$value = [System.Convert]::ToBoolean($cfg.($value))
    }
  }

}