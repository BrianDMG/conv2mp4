FROM mcr.microsoft.com/powershell

ARG GIT_CLONE='https://gitlab.com/BrianDMG/conv2mp4-ps.git'
ARG GIT_BRANCH='feature/docker'
ARG CONV2MP4_HOME='/app'
#ARG SCRIPT=${CONV2MP4_HOME}/conv2mp4-ps.ps1
#ARG FILES=${CONV2MP4_HOME}/files
#ARG CFG=${FILES}/cfg
#ARG LOG=${FILES}/log
#ARG IGNORE=${FILES}/ignore
#ARG PWSH_HOME=/usr/bin/pwsh
#ARG CUSTOM_BIN=/usr/local/bin/conv2mp4

ENV MEDIA_PATH=/media
ENV FFMPEG_BIN_DIR=/usr/bin
ENV HANDBRAKECLI_BIN_DIR=/usr/bin
ENV OUTPATH=/outpath

RUN apt update && \
    apt install -y software-properties-common && \
    add-apt-repository ppa:stebbins/handbrake-releases && \
    apt update && \
    apt install --no-install-recommends -y \
      cron \
      git \
      ffmpeg \
      handbrake-cli \
      nano &&\
    git clone --single-branch --branch ${GIT_BRANCH} ${GIT_CLONE} ${CONV2MP4_HOME} && \
    apt autoremove -y && \
    apt clean && \
    systemctl enable cron

#RUN ln -s ${CFG}/ / && \
#    ln -s ${LOG}/  / && \
#    ln -s ${IGNORE}/ / && \
#    mkdir /outpath

COPY test.ps1 ${CONV2MP4_HOME}

#Keepalive
CMD [ "pwsh", "/c", "/app/daemon.ps1" ]
#tail -f /dev/null