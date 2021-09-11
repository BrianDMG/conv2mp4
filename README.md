![conv2mp4](/files/listener/public/logo.svg "conv2mp4")

[![Main pipeline](https://img.shields.io/gitlab/pipeline/BrianDMG/conv2mp4/main?label=main%20pipeline&style=flat-square)](https://gitlab.com/%{project_path}/-/commits/main)
[![Dev pipeline](https://img.shields.io/gitlab/pipeline/BrianDMG/conv2mp4/development?label=development%20pipeline&style=flat-square)](https://gitlab.com/%{project_path}/-/commits/development)
[![Latest git release](https://img.shields.io/github/v/release/briandmg/conv2mp4?label=Latest%20git%20release&style=flat-square)](https://gitlab.com/BrianDMG/conv2mp4/-/releases#latest)
[![Latest Dockerhub release](https://img.shields.io/docker/v/bridmg/conv2mp4?label=Latest%20Dockerhub%20release&sort=semver&style=flat-square)](https://hub.docker.com/repository/docker/bridmg/conv2mp4/tags?page=1&ordering=last_updated)
[![Commits since last release](https://img.shields.io/github/commits-since/briandmg/conv2mp4/latest/development?style=flat-square)](https://gitlab.com/BrianDMG/conv2mp4/-/commits/development)
[![Code size](https://img.shields.io/github/languages/code-size/briandmg/conv2mp4?style=flat-square)](https://gitlab.com/BrianDMG/conv2mp4)
[![Github issues](https://img.shields.io/github/issues/briandmg/conv2mp4?style=flat-square)](https://github.com/BrianDMG/conv2mp4/issues)
[![Github stars](https://img.shields.io/github/stars/briandmg/conv2mp4?style=flat-square)](https://github.com/BrianDMG/conv2mp4/stargazers)

Powershell script that recursively searches through a user-defined file path and convert all videos of user-specified file types to MP4 with H264 video and AAC audio as needed using ffmpeg. If a conversion failure is detected, the script re-encodes the file with HandbrakeCLI. Upon successful encoding, Plex libraries are refreshed and source file is deleted.  The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server and increase video compatibility across platforms.


**Features**
- **Full automation**: Set a cron-formatted schedule, and convert/encode your files while you do something more interesting.
- **Detailed logging**: Allows easy tracking of what files are in the queue, overall queue progress, individual and cumulative file size gains and reductions, as well as total hours of video converted, how long it took to convert them, and the average encode speed.
- **Plex integration**: Refreshes Plex libraries upon completion of each item in the queue.
- **Garbage collection**: Allows user-specified file types to be deleted during each execution, keeping non-media files such as .nfo or thumbs.db from accumulating.

[Usage](/docs/USAGE.md) • [Configuration](/docs/CONFIGURATION.md)

<sub><sup>Want to [contribute](/docs/guidelines/CONTRIBUTING.md)? [Pull requests](/docs/guidelines/PULL_REQUEST_TEMPLATE.md) welcome!<br>
[GitLab](https://gitlab.com/BrianDMG/conv2mp4) | [Github](https://github.com/BrianDMG/conv2mp4) | [Dockerhub](https://hub.docker.com/repository/docker/bridmg/conv2mp4)</sub></sup>
