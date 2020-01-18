Write-Output "Initializing..."

#Import functions
. $prop.func_addignore
. $prop.func_appendlog
. $prop.func_comparefiles
. $prop.func_converttonewmp4
. $prop.func_deletelockfile
. $prop.func_failuredetected
. $prop.func_finalstatistics
. $prop.func_findcodec
. $prop.func_garbagecollection
. $prop.func_iflarger
. $prop.func_ifsame
. $prop.func_ifsmaller
. $prop.func_listfiles
. $prop.func_log
. $prop.func_plexrefresh
. $prop.func_printver

#Convert configuration to boolean
$cfg.keepSubs = [System.Convert]::ToBoolean($cfg.keepSubs)

# Time and format used for timestamps in the log
$time = {Get-Date -format "MM/dd/yy HH:mm:ss"}

# Get current time to store as start time for script
$script:scriptDurStart = (Get-Date -format "HH:mm:ss")

# Instantiate corrupted file array
$duds
$dudFiles = {$duds}.Invoke()

# Instantiate encoding failure array
$failures
$failedEncodes = {$failures}.Invoke()

# Initialize disk usage change to 0
$diskUsage = 0

# Initialize 'video length converted' to 0
$durTotal = [timespan]::fromseconds(0)