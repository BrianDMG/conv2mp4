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
$cfg.useOutPath = [System.Convert]::ToBoolean($cfg.useOutPath)
$cfg.setTitle = [System.Convert]::ToBoolean($cfg.setTitle)
$cfg.force2chCopy = [System.Convert]::ToBoolean($cfg.force2chCopy)
$cfg.keepSubs = [System.Convert]::ToBoolean($cfg.keepSubs)
$cfg.appendLog = [System.Convert]::ToBoolean($cfg.appendLog)
$cfg.usePlex = [System.Convert]::ToBoolean($cfg.usePlex)
$cfg.collectGarbage = [System.Convert]::ToBoolean($cfg.collectGarbage)
$cfg.useIgnore = [System.Convert]::ToBoolean($cfg.useIgnore)
# Time and format used for timestamps in the log
$time = {Get-Date -format "MM/dd/yy HH:mm:ss"}

# Get current time to store as start time for script
$scriptDurStart = (Get-Date)

# Instantiate corrupted file array
$duds
$dudFiles = {$duds}.Invoke()

# Instantiate encoding failure array
$failures
$failedEncodes = {$failures}.Invoke()

# Initialize disk usage change to 0
$diskUsage = 0

# Initialize 'video length converted' to 0
$vidDurTotal = [timespan]::fromseconds(0)