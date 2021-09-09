FROM mcr.microsoft.com/powershell:ubuntu-focal

ARG REVISION='local'

ENV APP_HOME=/app \
    MEDIA_PATH=/media \
    FFMPEG_BIN_DIR=/usr/bin \
    HANDBRAKECLI_BIN_DIR=/usr/bin \
    OUTPATH=/outpath \
    LISTENER_PORT=8082 \
    REVISION=${REVISION} \
    TERM=xterm

RUN apt-get update && \
    apt-get install -y \
      --no-install-recommends \
      software-properties-common=0.98.9.5 && \
    add-apt-repository ppa:stebbins/handbrake-releases && \
    apt-get update && \
    apt-get install \
      --no-install-recommends -y \
      ffmpeg=7:4.2.4-1ubuntu0.1 \
      handbrake-cli=1:1.3.3.1-zhb-1ppa1~focal1 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pwsh /c "Install-Module Pode -Force" && \
    pwsh /c "Install-Module powershell-yaml -Force"

COPY . ${APP_HOME}

HEALTHCHECK CMD pwsh /c "(Invoke-WebRequest -Method Get \
                -URI http://localhost:${LISTENER_PORT}/health).StatusCode"

CMD [ "pwsh", "/c", "/app/files/listener/daemon.ps1" ]