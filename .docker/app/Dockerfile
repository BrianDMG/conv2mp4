FROM mcr.microsoft.com/powershell:ubuntu-focal

ENV APP_HOME=/app
ENV MEDIA_PATH=/media
ENV FFMPEG_BIN_DIR=/usr/bin
ENV HANDBRAKECLI_BIN_DIR=/usr/bin
ENV OUTPATH=/outpath
ENV TERM=xterm

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
    rm -rf /var/lib/apt/lists/*

COPY . ${APP_HOME}

CMD [ "pwsh", "/c", "/app/files/init/daemon.ps1" ]