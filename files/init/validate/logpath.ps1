# Validate or create log path
If (-Not (Test-Path $prop.log_path)) {
	New-Item $prop.log_path -Force
}