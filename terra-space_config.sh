#!/bin/bash

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