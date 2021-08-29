# https://hub.docker.com/_/microsoft-powershell
FROM mcr.microsoft.com/powershell:alpine-3.12

# Change the shell to use Powershell directly for our commands
# instead of englobing them with pwsh -Command "MY_COMMAND"
SHELL [ "pwsh", "-Command" ]

RUN \
  # Sets values for a registered module repository
  Set-PSRepository \
    -ErrorAction Stop \
    -InstallationPolicy Trusted \
    -Name PSGallery             <# Name of the repository #> \
    -Verbose;                   <# Write verbose output #> \
  # Install PSScriptAnalyzer module (https://github.com/PowerShell/PSScriptAnalyzer/tags)
  Install-Module \
    -ErrorAction Stop \
    -Name PSScriptAnalyzer    <# Name of modules to install from the online gallery #> \
    -RequiredVersion 1.19.1   <# Exact version of a single module to install #> \
    -Verbose;

# Switch back to the default Linux shell
SHELL [ "/bin/sh" , "-c" ]