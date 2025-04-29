#!/bin/bash
set -euo pipefail

# Usage: ./2-upload-backup-files.sh /path/to/folder MAX_SIZE (e.g., 5G, 500M, 200K, 1000) s3://my-bucket

FOLDER_PATH="$1"
MAX_SIZE_HUMAN="$2"
S3_BUCKET="$3"

# Ensure AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it and configure credentials."
    exit 1
fi

# Function to convert human-readable size (e.g., 5G, 500M) to bytes
convert_to_bytes() {
  local size="$1"
  local unit=$(echo "$size" | grep -oEi '[KMGT]$')
  local number=$(echo "$size" | grep -oE '^[0-9]+')

  case "$unit" in
    K|k) echo $((number * 1024)) ;;
    M|m) echo $((number * 1024 * 1024)) ;;
    G|g) echo $((number * 1024 * 1024 * 1024)) ;;
    T|t) echo $((number * 1024 * 1024 * 1024 * 1024)) ;;
    "") echo "$number" ;;  # assume bytes if no unit
    *) echo "Invalid size unit: $unit" >&2; exit 2 ;;
  esac
}

# Function to convert bytes to human-readable (e.g., 1048576 -> 1.00M) using awk
bytes_to_human() {
  local bytes=$1
  if   [ "$bytes" -ge $((1024**3)) ]; then
    awk -v b="$bytes" 'BEGIN { printf("%.2fG", b/1024/1024/1024) }'
  elif [ "$bytes" -ge $((1024**2)) ]; then
    awk -v b="$bytes" 'BEGIN { printf("%.2fM", b/1024/1024) }'
  elif [ "$bytes" -ge 1024 ]; then
    awk -v b="$bytes" 'BEGIN { printf("%.2fK", b/1024) }'
  else
    printf "%dB" "$bytes"
  fi
}

# Validate arguments
if [ -z "$FOLDER_PATH" ] || [ -z "$MAX_SIZE_HUMAN" ] || [ -z "$S3_BUCKET" ]; then
  echo "Usage: $0 /path/to/folder MAX_SIZE (e.g., 5G, 500M) s3://my-bucket"
  exit 2
fi

if [ ! -d "$FOLDER_PATH" ]; then
  echo "Error: '$FOLDER_PATH' is not a directory or does not exist."
  exit 2
fi

# Convert and compare sizes
MAX_SIZE_BYTES=$(convert_to_bytes "$MAX_SIZE_HUMAN")
FOLDER_SIZE_BYTES=$(du -sb "$FOLDER_PATH" | cut -f1)
FOLDER_SIZE_HUMAN=$(bytes_to_human "$FOLDER_SIZE_BYTES")

if [ "$FOLDER_SIZE_BYTES" -gt "$MAX_SIZE_BYTES" ]; then
  echo "Error: Folder size ($FOLDER_SIZE_HUMAN) exceeds limit ($MAX_SIZE_HUMAN)"
  exit 1
fi

echo "Folder size ($FOLDER_SIZE_HUMAN) is within limit ($MAX_SIZE_HUMAN)"

# Perform the upload
cd "$FOLDER_PATH"


# aws s3 cp . "$S3_BUCKET" --recursive

echo "✅ Upload complete to $S3_BUCKET"
