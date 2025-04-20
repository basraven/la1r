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
      *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--dry-run] [--config CONFIG_FILE]"
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
          exclude_args_7z="$exclude_args_7z -xr!$exclude_pattern"
        else
          exclude_args_tar+=("--exclude=$exclude_pattern")
        fi
      fi
    done
  fi
  
  # Find all files and build file hashes
  local temp_hash_file=$(mktemp)
  local original_dir=$(pwd)
  local json_file="$original_dir/backup-hashes.json"
  
  # Build new hash file
  echo "Building file hashes for $source_path"
  cd "$source_path" || exit 1
  
  # Find all directories that contain files but exclude deepest level directories
  find . -type f -not -path "*/\.*" | while read -r file; do
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
      # Add to new hashes
      if [ "$DRY_RUN" = false ]; then
        echo "$parent_dir,$file,$file_hash" >> "$temp_hash_file"
      else
        echo "[DRY RUN] Would hash file: $file"
      fi
    fi
  done
  
  # Return to original directory
  cd "$original_dir" || exit 1
  
  # Read old hashes if they exist
  local changed_bytes=0
  
  if [ -f "$json_file" ]; then
    local old_hashes=$(cat "$json_file")
    
    # Compare hashes and calculate changed bytes
    while IFS=, read -r dir file hash; do
      if [ -n "$dir" ] && [ -n "$file" ] && [ -n "$hash" ]; then
        local full_path="$source_path/$file"
        # Use grep to find the old hash (if exists) for this file
        local old_hash=$(echo "$old_hashes" | grep -o "\"$file\":\"[^\"]*\"" | cut -d '"' -f 4)
        
        if [ "$old_hash" != "$hash" ]; then
          if [ -f "$full_path" ]; then
            local file_size=$(stat -c %s "$full_path")
            changed_bytes=$((changed_bytes + file_size))
          fi
        fi
      fi
    done < "$temp_hash_file"
  else
    # If no previous hash file, count all files as changed
    find "$source_path" -type f -not -path "*/\.*" | while read -r file; do
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
        if [ -f "$file" ]; then
          local file_size=$(stat -c %s "$file")
          changed_bytes=$((changed_bytes + file_size))
        fi
      fi
    done
  fi
  
  echo "Total changed bytes: $changed_bytes"
  
  # Create new JSON hash file
  if [ "$DRY_RUN" = false ]; then
    # Convert temp file to JSON format
    local new_hashes="{"
    while IFS=, read -r dir file hash; do
      if [ -n "$dir" ] && [ -n "$file" ] && [ -n "$hash" ]; then
        new_hashes="$new_hashes\"$file\":\"$hash\","
      fi
    done < "$temp_hash_file"
    # Remove trailing comma and close JSON
    new_hashes="${new_hashes%,}}"
    
    echo "$new_hashes" > "$json_file"
    echo "New hash file saved to $json_file"
  else
    echo "[DRY RUN] Would save new hash file to $json_file"
  fi
  
  rm -f "$temp_hash_file"
  
  # Process directories and zip/encrypt
  cd "$source_path" || exit 1
  
  # Find all directories that contain files but exclude deepest level directories
  # We need to get unique parent directories (deepest level - 1)
  local unique_dirs=$(find . -type f -not -path "*/\.*" | sed 's|/[^/]*$||' | sort | uniq)
  
  for dir in $unique_dirs; do
    # Skip if it's the root directory
    if [ "$dir" = "." ]; then
      continue
    fi
    
    # Check if directory matches any exclude pattern
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
    
    # Create archive name from directory
    local archive_name=$(basename "$dir")
    local parent_dir=$(dirname "$dir")
    if [ "$parent_dir" = "." ]; then
      parent_dir=""
    else
      parent_dir="/$parent_dir"
    fi
    
    local archive_path="$target_path/$archive_name"
    local archive_file=""
    
    # Compress directory - use strict string comparison with quotes
    if [[ "$COMPRESSION_TYPE" == "7zip" ]]; then
      if [ "$DRY_RUN" = false ]; then
        echo "Compressing $dir to $archive_path.7z with 7zip"
        # For 7zip, we can pass the compression arguments directly, write stdout to /dev/null, stderr is not redirected
        7z a $COMPRESSION_ARGS "$archive_path.7z" "$dir/"* $exclude_args_7z > /dev/null
        archive_file="$archive_path.7z"
      else
        echo "[DRY RUN] Would compress $dir to $archive_path.7z with 7zip"
        # echo "[DRY RUN] Using args: 7z a $COMPRESSION_ARGS \"$archive_path.7z\" \"$dir/\"* $exclude_args_7z"
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
      gpg --symmetric --cipher-algo AES256 --batch --passphrase-file ~/.backup-passphrase "$archive_file"
      rm -f "$archive_file"
      echo "Encrypted file saved to $archive_file.gpg"
    elif [ "$ENCRYPTION_TYPE" = "gpg" ] && [ "$DRY_RUN" = true ]; then
      echo "[DRY RUN] Would encrypt $archive_file with GPG"
    fi
  done
  
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