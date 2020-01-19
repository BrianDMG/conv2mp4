# Validate or create ignore path
If (-Not (Test-Path $prop.ignore_path)) {
    New-Item $prop.ignore_path -Force
}