# space-manager

Summary of Both Files

terra-space_config.sh: Contains configuration settings such as main directory, log file path, action modes, security paths, excluded patterns, and subdirectory configurations with specific device assignments and thresholds.
terra-space.sh: The main script that processes the directories based on the configuration, moving or wiping old directories as needed while logging the actions taken,

Installation and Usage Instructions
Create the Files: Create the two files in your desired location on the server (e.g., /glftpd/bin/terra-space.sh and /glftpd/bin/terra-space_config.sh).
Make the Script Executable: chmod +x /glftpd/bin/terra-space.sh and chmod +x /glftpd/bin/terra-space_config.sh	

Configure the Script:
Adjust the paths and settings in terra-space_config.sh as needed for your environment.
Ensure the log file path is writable by the user running the script.

Schedule with Cron (optional):

If you want to run this script automatically, you can add it to your crontab. For example, to run it every day at 1 AM: 
0 1 * * * /usr/local/bin/space_manager.sh

Testing: Initially run the script with DEBUG=true in terra-space_config.sh to test without performing actual deletions/moves | check log file.
