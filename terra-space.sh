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
# Fixed: This script now ensures it properly checks for recently created directories using mtime and logs directories considered for debugging.
###########################################################################################################
#
# Load the configuration
source /glftpd/bin/terra-space_config.sh  # Adjust this path as necessary
#
######################### FUNCTION DEFINITIONS #######################################
# Function to check free space on a device
check_free_space() {
    local device="$1"
    df -m "$device" | awk 'NR==2 {print $4}'
}

# Function to convert sizes based on OUTPUT_UNIT
convert_size() {
    local size_mb="$1"
    case "$OUTPUT_UNIT" in
        "GB")
            echo "$(bc <<< "scale=2; $size_mb / 1024") GB"  # Convert MB to GB
            ;;
        "TB")
            echo "$(bc <<< "scale=2; $size_mb / 1048576") TB"  # Convert MB to TB
            ;;
        *)
            echo "$size_mb MB"  # Default to MB
            ;;
    esac
}

# Function to log messages
log_message() {
    local action="$1"
    local item="$2"
    local message="$3"
    echo "$(date '+%a %b %e %T %Y') - $action $item - $message" >> "$LOG_FILE"
}

# Function to determine if item is within the security path
is_within_security_path() {
    local item="$1"
    [[ "$item" =~ $SECURITY_PATH ]]
}

# Main execution loop for managing space in specified subdirectories
for entry in "${SUBDIR_CONFIGS[@]}"; do
    IFS=':' read -r subdir device start_threshold stop_threshold archive_path <<< "$entry"

    # Check if the subdirectory exists
    if [[ ! -d "$MAIN_DIR/$subdir" ]]; then
        log_message "ERROR" "$subdir" "Subdirectory does not exist. Skipping."
        continue
    fi

    # **New Logic**: Count the directories in the subcategory
    dir_count=$(find "$MAIN_DIR/$subdir" -mindepth 1 -maxdepth 1 -type d | wc -l)

    # Skip if there are fewer than 5 directories
    if (( dir_count < 5 )); then
        log_message "INFO" "$subdir" "Fewer than 5 directories found. Skipping."
        continue
    fi

    # Get the oldest directory within the main subdirectory (exclude subdirectories like SAMPLE)
    oldest_dir=$(find "$MAIN_DIR/$subdir" -mindepth 1 -maxdepth 1 -type d -exec ls -td {} + | tail -n 1)
    
    # If there's no directory found, skip
    if [[ -z "$oldest_dir" ]]; then
        log_message "INFO" "$subdir" "No directories found for cleanup. Skipping."
        continue
    fi

    # Calculate the size of the oldest directory
    item_size=$(du -sm "$oldest_dir" | cut -f1)
    item_size_converted=$(convert_size "$item_size")
    item_name=$(basename "$oldest_dir")  # Get the base name of the item

    # Debug message
    log_message "[DEBUG] Action" "$oldest_dir" "$item_size_converted (simulation)"

    # If DEBUG mode is true, don't actually move or wipe the directory, just log the action
    if [[ "$DEBUG" == "true" ]]; then
        log_message "[DEBUG] SKIP ACTION" "$oldest_dir" "Simulation mode enabled. No action performed."
        continue
    fi

    # Check if space is needed and act accordingly
    free_space=$(check_free_space "$device")
    if (( free_space < stop_threshold )); then
        # Only move or wipe the directory if the free space is below the threshold
        if [[ "$ACTION_MODE" == "move" ]]; then
            # Move the oldest directory to the archive path
            if mv "$oldest_dir" "$archive_path"; then
                log_message "MOVE" "from $subdir $item_name" "Moved to /_ARCHIVE/${subdir} - Freed up $item_size_converted"
            else
                log_message "ERROR" "$oldest_dir" "Failed to move"
            fi
        elif [[ "$ACTION_MODE" == "wipe" ]]; then
            # Delete the oldest directory
            if rm -rf "$oldest_dir"; then
                log_message "WIPE" "from $subdir $item_name" "$item_size_converted"
            else
                log_message "ERROR" "$oldest_dir" "Failed to delete"
            fi
        fi
    else
        log_message "INFO" "$subdir" "Free space is above the threshold, no action required."
    fi
done
#eof
