Write-Output "Initializing..."

#Import functions
Get-ChildItem -Path $prop.func_basepath -Include "*.ps1" -Recurse |
    ForEach-Object {
        . $_
    }

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
$startScriptTime = (Get-Date)

# Instantiate corrupted file array
$duds
$dudFiles = {$duds}.Invoke()

# Instantiate encoding failure array
$failures
$failedEncodes = {$failures}.Invoke()

# Initialize disk usage change to 0
$diskUsageDelta = 0

# Initialize 'video length converted' to 0
$cumulativeVideoDuration = [timespan]::fromseconds(0)