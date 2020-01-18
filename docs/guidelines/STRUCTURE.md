# Folder structure

- **.gitignore**: list of files and directories to be ignored by git
- **conv2mp4-ps.ps1**: Main executable script
- **README.md**: Main readme documentation
- **docs**: Contains script documentation
    - **guidelines**: Contains code contribution guidelines and templates
- **files**: Contains all other script-related files
    - **cfg**: Contains configuration-related files
        - `config.template`
        - `config`
        - `config.bk`
    - **func**: Contains script functions
    - **ignore**: Contains the ignore list
    - **init**: Contains script initilization and validation-related scripts
        - **validate**: Contains configuration validation scripts
    - **lock**: Contains lock file while script is executing
    - **log**: Contains the log file
        - `conv2mp4-ps.log`
    - **prop**: Contains the properties file (static variables)