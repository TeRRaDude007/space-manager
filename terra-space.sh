#!/bin/bash
###########################################################################################################
# bump to V1.2 
# This is the main script, including all configurations, free space checking, logging, and handling of non-existent directories.
# Debug Logging for Missing Directories: added
###########################################################################################################
#
# Load the configuration
source /glftpd/bin/terra-space_config.sh  # Adjust this path as necessary
#
############################## END OF CONFIG ##############################################################
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

# Manage space by moving or wiping old directories
manage_space() {
    local subdir="$1"
    local device="$2"
    local start_threshold="$3"
    local stop_threshold="$4"
    local archive_path="$5"

    # Check if the subdirectory exists
    if [[ ! -d "$MAIN_DIR/$subdir" ]]; then
        if [[ "$DEBUG" == "true" ]]; then
            log_message "DEBUG" "$subdir" "Subdirectory $MAIN_DIR/$subdir does not exist. Skipping."
        fi
        return
    fi

    # Check free space on the device before starting actions
    local initial_free_space=$(check_free_space "$device")

    # Check if action is required
    if (( initial_free_space > start_threshold )); then
        log_message "INFO" "$subdir" "Free space ($(convert_size $initial_free_space)) is above the start threshold ($(convert_size $start_threshold)). No action taken."
        return
    fi

    log_message "INFO" "$subdir" "Starting space management as free space ($(convert_size $initial_free_space)) is below start threshold ($(convert_size $start_threshold))."

    # Iterate over items in the directory to delete/move them
    for item in "$MAIN_DIR/$subdir"/*; do
        # Ensure item is within the allowed security path
        if ! is_within_security_path "$item"; then
            log_message "SKIP" "$item" "Outside SECURITY_PATH ($SECURITY_PATH)"
            continue
        fi

        # Skip excluded files/directories
        for exclude in "${EXCLUDE_PATTERNS[@]}"; do
            [[ "$item" == *"$exclude"* ]] && continue 2
        done

        # Calculate size of item before deletion/move
        local item_size=$(du -sm "$item" | cut -f1)
        local item_size_converted=$(convert_size "$item_size")
        local item_name=$(basename "$item")  # Get the base name of the item

        if [[ "$DEBUG" == "true" ]]; then
            log_message "[DEBUG] ${ACTION_MODE}" "$item" "$item_size_converted (simulation)"
        else
            if [[ "$ACTION_MODE" == "move" ]]; then
                # Move item to the appropriate archive directory
                if mv "$item" "$archive_path"; then
                    log_message "MOVE" "from $subdir $item_name" "Moved to /_ARCHIVE/${subdir} - Freed up $item_size_converted"
                else
                    log_message "ERROR" "$item" "Failed to move"
                fi
            elif [[ "$ACTION_MODE" == "wipe" ]]; then
                # Delete item
                if rm -rf "$item"; then
                    log_message "WIPE" "from $subdir $item_name" "$item_size_converted"
                else
                    log_message "ERROR" "$item" "Failed to delete"
                fi
            fi
        fi

        # Re-check free space after each deletion/move
        local free_space=$(check_free_space "$device")
        if (( free_space > stop_threshold )); then
            log_message "INFO" "$subdir" "Stop threshold ($(convert_size $stop_threshold)) reached. Stopping further actions."
            break
        fi
    done
}

# Main execution loop for managing space in specified subdirectories
for entry in "${SUBDIR_CONFIGS[@]}"; do
    IFS=':' read -r subdir device start_threshold stop_threshold archive_path <<< "$entry"
    manage_space "$subdir" "$device" "$start_threshold" "$stop_threshold" "$archive_path"
done
#!/bin/bash

# Load the configuration
source /path/to/config.sh  # Adjust this path as necessary

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

# Manage space by moving or wiping old directories
manage_space() {
    local subdir="$1"
    local device="$2"
    local start_threshold="$3"
    local stop_threshold="$4"
    local archive_path="$5"

    # Check if the subdirectory exists
    if [[ ! -d "$MAIN_DIR/$subdir" ]]; then
        if [[ "$DEBUG" == "true" ]]; then
            log_message "DEBUG" "$subdir" "Subdirectory $MAIN_DIR/$subdir does not exist. Skipping."
        fi
        return
    fi

    # Check free space on the device before starting actions
    local initial_free_space=$(check_free_space "$device")

    # Check if action is required
    if (( initial_free_space > start_threshold )); then
        log_message "INFO" "$subdir" "Free space ($(convert_size $initial_free_space)) is above the start threshold ($(convert_size $start_threshold)). No action taken."
        return
    fi

    log_message "INFO" "$subdir" "Starting space management as free space ($(convert_size $initial_free_space)) is below start threshold ($(convert_size $start_threshold))."

    # Iterate over items in the directory to delete/move them
    for item in "$MAIN_DIR/$subdir"/*; do
        # Ensure item is within the allowed security path
        if ! is_within_security_path "$item"; then
            log_message "SKIP" "$item" "Outside SECURITY_PATH ($SECURITY_PATH)"
            continue
        fi

        # Skip excluded files/directories
        for exclude in "${EXCLUDE_PATTERNS[@]}"; do
            [[ "$item" == *"$exclude"* ]] && continue 2
        done

        # Calculate size of item before deletion/move
        local item_size=$(du -sm "$item" | cut -f1)
        local item_size_converted=$(convert_size "$item_size")
        local item_name=$(basename "$item")  # Get the base name of the item

        if [[ "$DEBUG" == "true" ]]; then
            log_message "[DEBUG] ${ACTION_MODE}" "$item" "$item_size_converted (simulation)"
        else
            if [[ "$ACTION_MODE" == "move" ]]; then
                # Move item to the appropriate archive directory
                if mv "$item" "$archive_path"; then
                    log_message "MOVE" "from $subdir $item_name" "Moved to /_ARCHIVE/${subdir} - Freed up $item_size_converted"
                else
                    log_message "ERROR" "$item" "Failed to move"
                fi
            elif [[ "$ACTION_MODE" == "wipe" ]]; then
                # Delete item
                if rm -rf "$item"; then
                    log_message "WIPE" "from $subdir $item_name" "$item_size_converted"
                else
                    log_message "ERROR" "$item" "Failed to delete"
                fi
            fi
        fi

        # Re-check free space after each deletion/move
        local free_space=$(check_free_space "$device")
        if (( free_space > stop_threshold )); then
            log_message "INFO" "$subdir" "Stop threshold ($(convert_size $stop_threshold)) reached. Stopping further actions."
            break
        fi
    done
}

# Main execution loop for managing space in specified subdirectories
for entry in "${SUBDIR_CONFIGS[@]}"; do
    IFS=':' read -r subdir device start_threshold stop_threshold archive_path <<< "$entry"
    manage_space "$subdir" "$device" "$start_threshold" "$stop_threshold" "$archive_path"
done
#eof
