#!/bin/bash

# Cloud Backup Script
# This script reads a cloud-backup-media-config.yml file and performs backup operations

set -e

# Check for required dependencies
check_dependencies() {
  local missing_deps=()
  
  # Check for yq (Go version)
  if ! command -v yq &> /dev/null; then
    missing_deps+=("yq (Go version - install with: wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O yq && chmod +x yq && sudo mv yq /usr/local/bin/)")
  fi
  
  # Check for 7zip
  if ! command -v 7z &> /dev/null; then
    missing_deps+=("7zip (install with 'apt-get install p7zip-full' or equivalent)")
  fi
  
  # Check for gpg
  if ! command -v gpg &> /dev/null; then
    missing_deps+=("gpg (install with 'apt-get install gnupg' or equivalent)")
  fi
  
  # Check for md5sum
  if ! command -v md5sum &> /dev/null; then
    missing_deps+=("md5sum (install with 'apt-get install coreutils' or equivalent)")
  fi
  
  # Check for jq
  if ! command -v jq &> /dev/null; then
    missing_deps+=("jq (install with 'apt-get install jq' or equivalent)")
  fi
  
  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "Error: Missing required dependencies:"
    for dep in "${missing_deps[@]}"; do
      echo "  - $dep"
    done
    exit 1
  fi
}

# Parse command line arguments
parse_args() {
  DRY_RUN=false
  CONFIG_FILE="cloud-backup-media-config.yml"
  json_file="backup-hashes.json"
  prev_json_file="prev-backup-hashes.json"
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      --json-file)
        json_file="$2"
        shift 2
        ;;
      --prev-json-file)
        prev_json_file="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--dry-run] [--config CONFIG_FILE] [--json-file JSON_FILE] [--prev-json-file PREV_JSON_FILE]"
        exit 1
        ;;
    esac
  done
  
  # Convert to absolute path
  if [[ "$CONFIG_FILE" != /* ]]; then
    CONFIG_FILE="$(pwd)/$CONFIG_FILE"
  fi
  
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found!"
    exit 1
  fi
  
  if [[ "$json_file" != /* ]]; then
    json_file="$(pwd)/$json_file"
  fi
  
  if [[ "$prev_json_file" != /* ]]; then
    prev_json_file="$(pwd)/$prev_json_file"
  fi
}

# Read config from YAML file
read_config() {
  COMPRESSION_TYPE=$(yq '.spec.compression.type' "$CONFIG_FILE")
  COMPRESSION_ARGS=$(yq '.spec.compression.arguments' "$CONFIG_FILE")
  ENCRYPTION_TYPE=$(yq '.spec.encryption.type' "$CONFIG_FILE")
  
  # Debug output of parsed config
  if [ "$DRY_RUN" = true ]; then
    echo "Parsed config values:"
    echo "COMPRESSION_TYPE: '$COMPRESSION_TYPE'"
    echo "COMPRESSION_ARGS: '$COMPRESSION_ARGS'"
    echo "ENCRYPTION_TYPE: '$ENCRYPTION_TYPE'"
  fi
  
  # Count sources
  SOURCE_COUNT=$(yq '.spec.sources | length' "$CONFIG_FILE")
}

# Process a single source
process_source() {
  local source_index=$1
  local source_name=$(yq ".spec.sources[$source_index].name" "$CONFIG_FILE")
  local source_path=$(yq ".spec.sources[$source_index].path" "$CONFIG_FILE")
  local target_path=$(yq ".spec.sources[$source_index].target" "$CONFIG_FILE")
  
  echo "Processing source: $source_name"
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would process source: $source_name"
    echo "[DRY RUN] Would process target: $target_path"
  fi
  
  # Create target directory if it doesn't exist
  if [ ! -d "$target_path" ]; then
    if [ "$DRY_RUN" = false ]; then
      echo "Creating target directory: $target_path"
      mkdir -p "$target_path"
    else
      echo "[DRY RUN] Would create target directory: $target_path"
    fi
  fi
  
  # Clear target directory if it's not empty
  if [ -n "$(ls -A "$target_path" 2>/dev/null)" ]; then
    if [ "$DRY_RUN" = false ]; then
      echo "Clearing target directory: $target_path"
      rm -rf "$target_path"/*
    else
      echo "[DRY RUN] Would clear target directory: $target_path"
    fi
  fi
  
  # Get exclude patterns
  local excludes_count=$(yq ".spec.sources[$source_index].excludes | length" "$CONFIG_FILE")
  local exclude_args_7z=""
  local exclude_args_tar=()
  
  if [ "$excludes_count" != "0" ]; then
    for ((j=0; j<excludes_count; j++)); do
      local exclude_pattern=$(yq ".spec.sources[$source_index].excludes[$j]" "$CONFIG_FILE")
      if [ -n "$exclude_pattern" ]; then
        if [[ "$COMPRESSION_TYPE" == "7zip" ]]; then
          exclude_args_7z="$exclude_args_7z -xr!\"$exclude_pattern\""
        else
          exclude_args_tar+=("--exclude=$exclude_pattern")
        fi
      fi
    done
  fi
  
  # Find all files and build file hashes
  local temp_hash_file=$(mktemp)
  local original_dir=$(pwd)
  
  # Initialize the JSON structure for backup-hashes.json if it doesn't exist
  if [ ! -f "$json_file" ]; then
    echo '{"folders": {}, "deleted_folders": []}' > "$json_file"
  elif ! jq -e '.folders' "$json_file" > /dev/null 2>&1 || ! jq -e '.deleted_folders' "$json_file" > /dev/null 2>&1; then
    # Convert old format to new format if needed
    local old_content=$(cat "$json_file")
    echo "{\"folders\": $old_content, \"deleted_folders\": []}" > "$json_file"
  fi
  
  # Build new hash file
  echo "Building file hashes for $source_path"
  cd "$source_path" || exit 1
  
  # Create a temporary directories map
  local temp_dirs_map=$(mktemp)
  echo "{}" > "$temp_dirs_map"
  
  # Find all directories that contain files but exclude deepest level directories
  find . -type f -not -path "*/\.*" -print0 | while IFS= read -r -d '' file; do
    # Get parent directory (deepest level - 1)
    dir=$(dirname "$file")
    parent_dir=$(dirname "$dir")
    
    # Skip if any exclude pattern matches
    local exclude_match=false
    if [ "$excludes_count" != "0" ]; then
      for ((j=0; j<excludes_count; j++)); do
        local exclude_pattern=$(yq ".spec.sources[$source_index].excludes[$j]" "$CONFIG_FILE")
        if [[ "$file" == *"$exclude_pattern"* ]]; then
          exclude_match=true
          break
        fi
      done
    fi
    
    if [ "$exclude_match" = false ]; then
      # Compute hash for the file
      local file_hash=$(md5sum "$file" | awk '{print $1}')
      # Append to accumulated hash for the directory
      local dir_name=$(basename "$dir")
      # Update the directory hash in the map
      local dir_path="${dir#./}"
      if [ "$dir_path" = "" ]; then
        dir_path="."
      fi
      
      # Update the directory hash by combining all file hashes
      if jq -e ".\"$dir_path\"" "$temp_dirs_map" > /dev/null 2>&1; then
        local current_hash=$(jq -r ".\"$dir_path\"" "$temp_dirs_map")
        local new_hash=$(echo -n "$current_hash$file_hash" | md5sum | awk '{print $1}')
        jq --arg path "$dir_path" --arg hash "$new_hash" '.[$path] = $hash' "$temp_dirs_map" > "${temp_dirs_map}.tmp" && mv "${temp_dirs_map}.tmp" "$temp_dirs_map"
      else
        jq --arg path "$dir_path" --arg hash "$file_hash" '.[$path] = $hash' "$temp_dirs_map" > "${temp_dirs_map}.tmp" && mv "${temp_dirs_map}.tmp" "$temp_dirs_map"
      fi
      
      # Add to new hashes
      if [ "$DRY_RUN" = false ]; then
        printf "%s,%s,%s\n" "$dir_path" "$file" "$file_hash" >> "$temp_hash_file"
      else
        echo "[DRY RUN] Would hash file: $file"
      fi
    fi
  done
  
  # Return to original directory
  cd "$original_dir" || exit 1
  
  # Get the list of all new folders that we found in this run
  local new_folders=$(jq -r 'keys[]' "$temp_dirs_map" 2>/dev/null || echo "")
  
  # Get the existing deleted folders list from backup-hashes.json
  local existing_deleted_folders=$(jq -r '.deleted_folders[]' "$json_file" 2>/dev/null || echo "")
  local deleted_folders_array=()
  
  # Add existing deleted folders to our array
  while IFS= read -r folder; do
    if [ -n "$folder" ]; then
      deleted_folders_array+=("$folder")
    fi
  done <<< "$existing_deleted_folders"
  
  # Create a temporary file to store prev folders
  local temp_prev_folders=$(mktemp)
  
  # Read previous hash file if it exists
  if [ -f "$prev_json_file" ]; then
    # Check if prev file has the new structure
    if jq -e '.folders' "$prev_json_file" > /dev/null 2>&1; then
      # New structure
      jq -r '.folders | keys[]' "$prev_json_file" > "$temp_prev_folders" 2>/dev/null
    else
      # Old structure
      jq -r 'keys[]' "$prev_json_file" > "$temp_prev_folders" 2>/dev/null
    fi
    
    # Find folders that existed in previous backup but not in current backup
    while IFS= read -r prev_folder; do
      if [ -n "$prev_folder" ]; then
        # Check if the folder exists in the new hash map
        if ! jq -e "has(\"$prev_folder\")" "$temp_dirs_map" > /dev/null 2>&1; then
          # Check if it's not already in our deleted folders array
          local already_deleted=false
          for deleted in "${deleted_folders_array[@]}"; do
            if [ "$deleted" = "$prev_folder" ]; then
              already_deleted=true
              break
            fi
          done
          
          if [ "$already_deleted" = false ]; then
            echo "Adding $prev_folder to deleted_folders as it's no longer present"
            deleted_folders_array+=("$prev_folder")
          fi
        fi
      fi
    done < "$temp_prev_folders"
  fi
  
  # Clean up temp file
  rm -f "$temp_prev_folders"
  
  # Create a new backup-hashes.json structure
  local new_json=""
  
  # Create folders object with updated hashes
  local folders_json="{}"
  while IFS= read -r dir_path; do
    if [ -n "$dir_path" ]; then
      local dir_hash=$(jq -r ".\"$dir_path\"" "$temp_dirs_map")
      folders_json=$(echo "$folders_json" | jq --arg path "$dir_path" --arg hash "$dir_hash" '.[$path] = $hash')
    fi
  done <<< "$new_folders"
  
  # Create deleted_folders array
  local deleted_json="[]"
  if [ ${#deleted_folders_array[@]} -gt 0 ]; then
    deleted_json=$(printf '%s\n' "${deleted_folders_array[@]}" | jq -R . | jq -s .)
  fi
  
  # Combine into final json
  new_json=$(jq -n --argjson folders "$folders_json" --argjson deleted "$deleted_json" '{folders: $folders, deleted_folders: $deleted}')
  
  # Save updated JSON
  if [ "$DRY_RUN" = false ]; then
    echo "$new_json" > "$json_file"
    echo "Updated hash file saved to $json_file"
  else
    echo "[DRY RUN] Would save updated hash file to $json_file"
    echo "[DRY RUN] Deleted folders count: ${#deleted_folders_array[@]}"
  fi
  
  # Process directories and zip/encrypt
  cd "$source_path" || exit 1
  
  # Fix: Find directories that contain files directly (not just subdirectories)
  local temp_dirs_file=$(mktemp)
  # Get all directories first
  find . -type d -not -path "*/\.*" | sort > "$temp_dirs_file"
  
  # Create a temporary file to record processed directories
  local processed_dirs=$(mktemp)
  
  # Process each directory to determine if it should be archived
  while IFS= read -r dir; do
    # Skip if it's the root directory
    if [ "$dir" = "." ]; then
      continue
    fi
    
    # Skip if directory matches any exclude pattern
    local exclude_match=false
    if [ "$excludes_count" != "0" ]; then
      for ((j=0; j<excludes_count; j++)); do
        local exclude_pattern=$(yq ".spec.sources[$source_index].excludes[$j]" "$CONFIG_FILE")
        if [[ "$dir" == *"$exclude_pattern"* ]]; then
          exclude_match=true
          break
        fi
      done
    fi
    
    if [ "$exclude_match" = true ]; then
      echo "Skipping excluded directory: $dir"
      continue
    fi
    
    # Fix: Check if this directory contains files directly
    if [ -n "$(find "$dir" -maxdepth 1 -type f -not -path "*/\.*" 2>/dev/null)" ]; then
      # Check if any parent directory of this one has already been processed
      local parent_processed=false
      local current_dir="$dir"
      local dir_depth=$(echo "$dir" | tr -cd '/' | wc -c)
      
      while [ "$current_dir" != "." ] && [ "$current_dir" != "./" ]; do
        current_dir=$(dirname "$current_dir")
        if grep -q "^$current_dir$" "$processed_dirs"; then
          parent_processed=true
          break
        fi
      done
      
      # Skip if any parent has been processed to avoid double-inclusion
      if [ "$parent_processed" = true ]; then
        echo "Skipping $dir as a parent directory has already been processed"
        continue
      fi
      
      echo "$dir" >> "$processed_dirs"
      
      # Create the same directory structure in the target
      local rel_dir="${dir#./}"
      local dir_name=$(basename "$rel_dir")
      local parent_path=$(dirname "$rel_dir")
      local target_dir="$target_path/$parent_path"
      
      # Create target directory structure if it doesn't exist
      if [ "$DRY_RUN" = false ]; then
        mkdir -p "$target_dir"
      else
        echo "[DRY RUN] Would create directory structure: $target_dir"
      fi
      
      # Now we place the archive in the correct nested location
      local archive_path="$target_dir/$dir_name"
      local archive_file=""
      
      # Check if we need to create the archive by comparing hashes
      local should_create_archive=true
      local dir_path="${dir#./}"
      
      # Check if the directory hash exists in both current and previous backups
      local current_hash=""
      local prev_hash=""
      
      current_hash=$(jq -r ".\"$dir_path\"" "$temp_dirs_map" 2>/dev/null || echo "")
      
      if [ -f "$prev_json_file" ]; then
        if jq -e '.folders' "$prev_json_file" > /dev/null 2>&1; then
          # New structure
          prev_hash=$(jq -r ".folders[\"$dir_path\"]" "$prev_json_file" 2>/dev/null || echo "")
        else
          # Old structure
          prev_hash=$(jq -r ".[\"$dir_path\"]" "$prev_json_file" 2>/dev/null || echo "")
        fi
      fi
      
      # Compare current and previous hash to determine if archive is needed
      if [ -n "$prev_hash" ] && [ -n "$current_hash" ] && [ "$prev_hash" = "$current_hash" ]; then
        should_create_archive=false
        echo "Skipping archive for $dir_path - hashes match between current and previous backup"
      elif [ -z "$prev_hash" ]; then
        # No previous hash, follow standard behavior
        should_create_archive=true
        echo "Creating archive for $dir_path - no previous hash found"
      else
        echo "Creating archive for $dir_path - hashes differ between current and previous backup"
      fi
      
      # Compress directory if needed - use strict string comparison with quotes
      if [ "$should_create_archive" = true ]; then
        if [[ "$COMPRESSION_TYPE" == "7zip" ]]; then
          if [ "$DRY_RUN" = false ]; then
            echo "Compressing $dir to $archive_path.7z with 7zip"
            # For 7zip, we can pass the compression arguments directly
            7z a $COMPRESSION_ARGS "$archive_path.7z" "$dir/"* $exclude_args_7z > /dev/null
            archive_file="$archive_path.7z"
          else
            echo "[DRY RUN] Would compress $dir to $archive_path.7z with 7zip"
            archive_file="$archive_path.7z"
          fi
        else
          if [ "$DRY_RUN" = false ]; then
            echo "Compressing $dir to $archive_path.tar.gz with tar"
            # For tar, place exclude options before other arguments
            if [ ${#exclude_args_tar[@]} -gt 0 ]; then
              tar "${exclude_args_tar[@]}" -czf "$archive_path.tar.gz" -C "$dir" .
            else
              tar -czf "$archive_path.tar.gz" -C "$dir" .
            fi
            archive_file="$archive_path.tar.gz"
          else
            echo "[DRY RUN] Would compress $dir to $archive_path.tar.gz with tar"
            if [ ${#exclude_args_tar[@]} -gt 0 ]; then
              echo "[DRY RUN] Using excludes: ${exclude_args_tar[*]}"
            fi
            archive_file="$archive_path.tar.gz"
          fi
        fi
        
        # Encrypt archive if specified
        if [ "$ENCRYPTION_TYPE" = "gpg" ] && [ "$DRY_RUN" = false ]; then
          echo "Encrypting $archive_file"
          gpg --encrypt --sign --yes --cipher-algo AES256 --armor --compress-algo none -r automation@la1r.com "$archive_file"
          rm -f "$archive_file"
          echo "Encrypted file saved to $archive_file.gpg"
        elif [ "$ENCRYPTION_TYPE" = "gpg" ] && [ "$DRY_RUN" = true ]; then
          echo "[DRY RUN] Would encrypt $archive_file with GPG"
        fi
      fi
    fi
  done < "$temp_dirs_file"
  
  # Clean up temporary files
  rm -f "$temp_dirs_file" "$processed_dirs" "$temp_dirs_map" "$temp_hash_file"
  
  cd "$original_dir" || exit 1
}

# Main function
main() {
  check_dependencies
  parse_args "$@"
  read_config
  
  echo "Cloud Backup Script"
  echo "-------------------"
  echo "Config file: $CONFIG_FILE"
  echo "Dry run: $DRY_RUN"
  echo "Compression type: $COMPRESSION_TYPE"
  if [ -n "$COMPRESSION_ARGS" ] && [ "$COMPRESSION_ARGS" != "null" ]; then
    echo "Compression args: $COMPRESSION_ARGS"
  fi
  echo "Encryption type: $ENCRYPTION_TYPE"
  echo "Sources to process: $SOURCE_COUNT"
  echo "-------------------"
  
  for ((i=0; i<SOURCE_COUNT; i++)); do
    process_source "$i"
  done
  
  echo "Backup process completed successfully!"
}

# Run the script
main "$@"