FROM mcr.microsoft.com/powershell:lts-arm32v7-ubuntu-18.04

ARG GIT_CLONE='https://github.com/BrianDMG/conv2mp4-ps.git'
ARG GIT_BRANCH='feature/docker'
ARG CONV2MP4_HOME='/conv2mp4-ps'
ARG SCRIPT=${CONV2MP4_HOME}/conv2mp4-ps.ps1
ARG FILES=${CONV2MP4_HOME}/files
ARG CFG=${FILES}/cfg
ARG LOG=${FILES}/log
ARG IGNORE=${FILES}/ignore
ARG PWSH_HOME=/usr/bin/pwsh
ARG CUSTOM_BIN=/usr/local/bin/conv2mp4

ENV MEDIA_PATH=/media
ENV FFMPEG_BIN_DIR=/usr/bin
ENV HANDBRAKECLI_BIN_DIR=/usr/bin
ENV OUTPATH=/outpath

#Install handbrake_cli
#RUN apt update && \
#    apt install -y software-properties-common && \
#    add-apt-repository -y ppa:stebbins/handbrake-releases && \
#    apt update && \
#    apt install -y handbrake-cli

RUN apt update && \
    apt install --no-install-recommends -y \
      git \
      ffmpeg && \
    git clone --single-branch --branch ${GIT_BRANCH} ${GIT_CLONE} && \
#    apt remove -y \
#      git && \
    apt autoremove -y && \
    apt clean && \
    echo "#!${PWSH_HOME} \n/${SCRIPT}" > ${CUSTOM_BIN} && \
    chmod +x /usr/local/bin/conv2mp4

RUN ln -s ${CFG}/ / && \
    ln -s ${LOG}/  / && \
    ln -s ${IGNORE}/ / && \
    mkdir /outpath

#Keepalive
CMD tail -f /dev/null