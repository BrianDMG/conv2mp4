# **Usage**

To use this script on a Windows computer, simply right click **conv2mp4-ps.ps1** and choose "*Run with Powershell*". Additionally, you can run the script as a [scheduled task](/docs/SCHEDULED_TASK.md) for full automation.

* **conv2mp4-ps.ps1**: the executable script.
* **files\cfg\config**: configuration file, contains user-defined variables. For configuration instructions, see [configuration](/docs/CONFIGURATION.md).
    - *NOTE: Make a copy of config.template, rename it `config` and customize your settings there*

To use the Docker image for the script:

docker-compose:

 conv2mp4:
```
    image: registry.gitlab.com/briandmg/conv2mp4-ps
    container_name: conv2mp4
    volumes:
      - /path/to/conv2mp4/cfg:/cfg          #Local path to your config file
      - /path/to/conv2mp4/log:/log          #Optional, allows for persistent log
      - /path/to/conv2mp4/ignore:/ignore    #Optional, allows for persistent ignore list
      - /path/to/conv2mp4/lock:/lock        #Optional, allows for persistent lock file
      - /path/to/media:/media               #Path to media to be converted
      - /etc/localtime:/etc/localtime:ro    #Syncs container time to host time
    ports:
      - 8082:8082
    restart: unless-stopped
```
