Write-Output "Initializing..."

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