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
    local item_count=0  # Counter for moved or deleted items

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

    # **NEW**: Count eligible items for deletion/moving
    local eligible_items=0
    for item in "$MAIN_DIR/$subdir"/*; do
        # Ensure item is within the allowed security path and not excluded
        if is_within_security_path "$item"; then
            local skip=false
            for exclude in "${EXCLUDE_PATTERNS[@]}"; do
                [[ "$item" == *"$exclude"* ]] && skip=true && break
            done
            [[ "$skip" == "false" ]] && ((eligible_items++))
        fi
    done

    # **NEW**: Check if there are enough items to process
    if (( eligible_items < MAX_ITEMS_PER_RUN )); then
        log_message "INFO" "$subdir" "Less than $MAX_ITEMS_PER_RUN eligible items found. Skipping."
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
                    ((item_count++))  # Increment the counter
                else
                    log_message "ERROR" "$item" "Failed to move"
                fi
            elif [[ "$ACTION_MODE" == "wipe" ]]; then
                # Delete item
                if rm -rf "$item"; then
                    log_message "WIPE" "from $subdir $item_name" "$item_size_converted"
                    ((item_count++))  # Increment the counter
                else
                    log_message "ERROR" "$item" "Failed to delete"
                fi
            fi
        fi

        # Stop if we've reached the maximum number of items processed
        if (( item_count >= MAX_ITEMS_PER_RUN )); then
            log_message "INFO" "$subdir" "Maximum of $MAX_ITEMS_PER_RUN items processed for $subdir. Stopping further actions."
            break
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
