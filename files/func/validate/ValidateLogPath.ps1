# Validate or create log path
Function ValidateLogPath {
    param(
        [String]$Path
    )

    If (-Not (Test-Path $Path)) {
        Try {
            Write-Output "Log not found at $Path - creating..."
            New-Item $Path -Force
        }
        Catch {
            #TODO Finish catch condition
        }
    }
}