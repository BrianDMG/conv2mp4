# Create lock file (for the purpose of ensuring only one instance of this script is running)
If (-Not (Test-Path $prop.lock_path)) {
    New-Item $prop.lock_path -Force
}
Else {
    Write-Output "Script is already running in another instance. Waiting..." 
    Do {
        test-path $prop.lock_path > $null
        Start-Sleep 10
    }
    Until (-Not (Test-Path $prop.lock_path))
    Write-Output "Other instance ended. Continuing..."
    New-Item $prop.lock_path -Force
}
Clear-Host