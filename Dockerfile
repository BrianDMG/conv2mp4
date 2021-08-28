FROM mcr.microsoft.com/powershell:ubuntu-focal

ENV APP_HOME=/app
ENV MEDIA_PATH=/media
ENV FFMPEG_BIN_DIR=/usr/bin
ENV HANDBRAKECLI_BIN_DIR=/usr/bin
ENV OUTPATH=/outpath
ENV TERM=xterm

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:stebbins/handbrake-releases && \
    apt-get update && \
    apt-get install \
      --no-install-recommends -y \
      ffmpeg \
      handbrake-cli && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY . /app

CMD [ "pwsh", "/c", "/app/files/docker/daemon.ps1" ]