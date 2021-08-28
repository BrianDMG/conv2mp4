FROM mcr.microsoft.com/powershell:ubuntu-focal

ENV APP_HOME=/app
ENV MEDIA_PATH=/media
ENV FFMPEG_BIN_DIR=/usr/bin
ENV HANDBRAKECLI_BIN_DIR=/usr/bin
ENV OUTPATH=/outpath
ENV TERM=xterm

RUN apt update && \
    apt install -y software-properties-common && \
    add-apt-repository ppa:stebbins/handbrake-releases && \
    apt update && \
    apt install \
      --no-install-recommends -y \
      ffmpeg \
      handbrake-cli && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

COPY . /app

CMD [ "pwsh", "/c", "/app/files/docker/daemon.ps1" ]