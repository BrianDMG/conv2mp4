# https://hub.docker.com/_/microsoft-powershell
FROM mcr.microsoft.com/powershell:alpine-3.12

# Change the shell to use Powershell directly for our commands
# instead of englobing them with pwsh -Command "MY_COMMAND"
SHELL [ "pwsh", "-Command" ]

RUN \
  #Sets values for a registered module repository
  Set-PSRepository \
    -ErrorAction Stop \
    -InstallationPolicy Trusted \
    -Name PSGallery \
    -Verbose; \
  #Install PSScriptAnalyzer module
  Install-Module \
    -ErrorAction Stop \
    -Name PSScriptAnalyzer \
    -RequiredVersion 1.19.1  \
    -Verbose;

# Switch back to the default Linux shell
SHELL [ "/bin/sh" , "-c" ]