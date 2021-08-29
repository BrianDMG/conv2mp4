<# #Load properties file
$propFile = Convert-Path "$($env:APP_HOME)\files\prop\properties"
$propRawString = Get-Content "$propFile" | Out-String
$propStringToConvert = $propRawString -replace '\\', '\\'
$prop = ConvertFrom-StringData $propStringToConvert
Remove-Variable -Name propFile, propRawString, propSTringToConvert

#Load configuration
$cfgRawString = Get-Content "$($prop.cfg_path)" | Out-String
$cfgStringToConvert = $cfgRawString -replace '\\', '\\'
$cfg = ConvertFrom-StringData $cfgStringToConvert
Remove-Variable -Name cfgRawString, cfgStringToConvert #>

# Specify the Execution times
$TriggerTimes = @(
  '8:32PM',
  '4:12PM',
  '4:12AM',
  '2:00AM',
  '1:00AM'
)
# Sort in chronologic order
#  assuming the times format are the same
$TriggerTimes = $TriggerTimes | Sort-Object

foreach ($t in $TriggerTimes)
{
    # Past time ?
    if((Get-Date) - (Get-Date -Date $t))
    {
        # Sleeping
        while ((Get-Date -Date $t) -gt (Get-Date))
        {
            # Sleep for the remaining time
            (Get-Date -Date $t) - (Get-Date) | Start-Sleep
        }

        # Trigger event
        #  insert your code here
        "# TriggerTime: '$t' - Executing my code here!"

    }
    else{
        "Belong to the past: '$t'"
    }
}