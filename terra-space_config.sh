#!/bin/bash
# bump to V1.3
###########################################################################################################
# Changelog.....:
# - v1.2
# This is the main script, including all configurations, free space checking, logging, and handling of non-existent directories.
# Debug Logging for Missing Directories: added
# - V1.3
# Minimum Item Check: Before attempting deletions/moves, manage_space ensures that at least MAX_ITEMS_PER_RUN eligible items are in the subdirectory.
# Size Conversion: Output size units are adjustable (MB, GB, or TB).
# Logging: Detailed logs for each action, including simulation logs if DEBUG="true".
# Loop Control: Stops processing when either MAX_ITEMS_PER_RUN is reached or free space exceeds stop_threshold.
# Skipping [NUKED]- Directories: Any directory whose name starts with [NUKED]- will be skipped and logged as "SKIP".
# Skipping (incomplete)- Symlinks: Any symbolic link with a name that starts with (incomplete)- will also be skipped and logged as "SKIP".
###########################################################################################################
#
#  CONFIG BELOW 
#

# Main directory where subdirectories are located
MAIN_DIR="/glftpd/site"

# Log file path
LOG_FILE="/glftpd/tmp/freespace.log"  # Adjust as needed

# Security path to restrict deletions
SECURITY_PATH="/glftpd/site/.*/"

# Action mode: either "move" or "wipe"
ACTION_MODE="wipe"  # or "move"

# Output size units: "MB", "GB", or "TB"
OUTPUT_UNIT="GB"

# Debug mode: set to "true" for testing, "false" for production
DEBUG="true"

# Excluded patterns to skip certain directories or files
EXCLUDE_PATTERNS=("lost&found")

# Maximum items to process per subdirectory in one run
MAX_ITEMS_PER_RUN=5

## Subdirectory configurations with specific device and thresholds in MB
## Format: "subdirectory:device:start_threshold:stop_threshold" 
## WHEN WIPE
SUBDIR_CONFIGS=(
  "MP3:/dev/nvme0n1:25000:30000"   # /glftpd/site/movies on /dev/sda with 25GB start and 30GB stop threshold
  "0DAYS:/dev/nvme0n1:25000:30000"     # /glftpd/site/apps on /dev/sdb with 50GB start and 60GB stop threshold
  "FLAC:/dev/nvme0n1:25000:30000"    # /glftpd/site/music on /dev/sda with 25GB start and 30GB stop threshold
)

## Format: "subdirectory:device:start_threshold:stop_threshold:archive_path" 
## WHEN MOVE to ARCHIVE
#SUBDIR_CONFIGS=(
#    "TV-BLURAY:/dev/sdb:60000:30000:/glftpd/site/_ARCHIVE/TV-BLURAY"
#    "FLAC:/dev/sda:60000:30000:/glftpd/site/_ARCHIVE/FLAC"
#    "MP3:/dev/sda:60000:30000:/glftpd/site/_ARCHIVE/MP3"
#    "APPS:/dev/sdb:60000:30000:/glftpd/site/_ARCHIVE/APPS"
#)
#eof
