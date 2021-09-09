![conv2mp4](/files/listener/public/logo.svg "conv2mp4")

Powershell script that recursively searches through a user-defined file path and convert all videos of user-specified file types to MP4 with H264 video and AAC audio as needed using ffmpeg. If a conversion failure is detected, the script re-encodes the file with HandbrakeCLI. Upon successful encoding, Plex libraries are refreshed and source file is deleted.  The purpose of this script is to reduce the amount of transcoding CPU load on a Plex server and increase video compatibility across platforms.

[![release](https://img.shields.io/docker/v/bridmg/conv2mp4?sort=date)](https://gitlab.com/BrianDMG/conv2mp4-ps/-/tags)
[![pipeline status](https://img.shields.io/gitlab/pipeline/BrianDMG/conv2mp4-ps/feature-docker?label=pipeline)](https://gitlab.com/%{project_path}/-/commits/feature-docker)
[![dockerhub pulls](https://img.shields.io/docker/pulls/bridmg/conv2mp4)](https://hub.docker.com/repository/docker/bridmg/conv2mp4)

**Features**
- **Full automation**: Set a cron-formatted schedule, and convert/encode your files while you do something more interesting.
- **Detailed logging**: Allows easy tracking of what files are in the queue, overall queue progress, individual and cumulative file size gains and reductions, as well as total hours of video converted, how long it took to convert them, and the average encode speed.
- **Plex integration**: Refreshes Plex libraries upon completion of each item in the queue.
- **Garbage collection**: Allows user-specified file types to be deleted during each execution, keeping non-media files such as .nfo or thumbs.db from accumulating.

[Usage](/docs/USAGE.md) • [Configuration](/docs/CONFIGURATION.md)

<sub><sup>Want to [contribute](https://github.com/BrianDMG/conv2mp4-ps/blob/master/docs/guidelines/CONTRIBUTING.md)? [Pull requests](https://github.com/BrianDMG/conv2mp4-ps/blob/master/docs/guidelines/PULL_REQUEST_TEMPLATE.md) welcome!<br>
[GitLab](https://gitlab.com/BrianDMG/conv2mp4-ps) | [Github](https://github.com/BrianDMG/conv2mp4-ps) | [Dockerhub](https://hub.docker.com/repository/docker/bridmg/conv2mp4)</sub></sup>
