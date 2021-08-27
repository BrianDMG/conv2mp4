FROM mcr.microsoft.com/powershell

ARG CONV2MP4_HOME='/app'

ENV APP_HOME=/app
ENV MEDIA_PATH=/media
ENV FFMPEG_BIN_DIR=/usr/bin
ENV HANDBRAKECLI_BIN_DIR=/usr/bin
ENV OUTPATH=/outpath

RUN apt update && \
    apt install -y software-properties-common && \
    add-apt-repository ppa:stebbins/handbrake-releases && \
    apt update && \
    apt install --no-install-recommends -y \
      ffmpeg \
      handbrake-cli \
      nano &&\
    apt autoremove -y && \
    apt clean

COPY . /app

CMD [ "pwsh", "/c", "/app/files/docker/daemon.ps1" ]