#!/bin/bash

# Configurable global file size limit
MAX_TOTAL_SIZE_GB=5                      # Total max file size allowed (in GB)
MAX_TOTAL_SIZE_BYTES=$((MAX_TOTAL_SIZE_GB * 1024 * 1024 * 1024))
CURRENT_TOTAL_SIZE=0
TOTAL_FILES_CREATED=0

MAX_DEPTH=8
ROOT="media"
mkdir -p "$ROOT"

# Function to convert bytes to human-readable format (e.g., 10MB, 2GB)
human_readable_size() {
  local size=$1
  for unit in B KB MB GB TB; do
    if (( size < 1024 )); then
      echo "$size $unit"
      return
    fi
    size=$((size / 1024))
  done
}

# Create random files (fake image/video data)
generate_files() {
  local folder=$1
  local num_files=$((RANDOM % 5 + 1))  # 1–5 files

  for ((i=0; i<num_files; i++)); do
    # Stop if we've reached the global size limit
    if (( CURRENT_TOTAL_SIZE >= MAX_TOTAL_SIZE_BYTES )); then
      return
    fi

    local file_type file_name bs count size_bytes

    if ((RANDOM % 2 == 0)); then
      file_type="image"
      file_name="image_$RANDOM.jpg"
      local size_kb=$((RANDOM % (5120 - 10 + 1) + 10))  # 10KB–5MB
      bs=1024
      count=$size_kb
      size_bytes=$((size_kb * 1024))
    else
      file_type="video"
      file_name="video_$RANDOM.mp4"
      local size_mb=$((RANDOM % (500 - 1 + 1) + 1))  # 1MB–500MB
      bs=1M
      count=$size_mb
      size_bytes=$((size_mb * 1024 * 1024))
    fi

    # Check if this file would exceed the global limit
    if (( CURRENT_TOTAL_SIZE + size_bytes > MAX_TOTAL_SIZE_BYTES )); then
      return
    fi

    dd if=/dev/urandom of="$folder/$file_name" bs=$bs count=$count status=none
    CURRENT_TOTAL_SIZE=$((CURRENT_TOTAL_SIZE + size_bytes))
    TOTAL_FILES_CREATED=$((TOTAL_FILES_CREATED + 1))
  done
}

# Recursive folder generation
generate_subtree() {
  local current_folder=$1
  local current_depth=$2

  # Add random files to current folder
  generate_files "$current_folder"

  # Decide number of subfolders to create (can be 0)
  local num_subfolders=$((RANDOM % 4)) # 0–3 subfolders

  for ((i=0; i<num_subfolders; i++)); do
    local subfolder="$current_folder/folder_$RANDOM"
    mkdir -p "$subfolder"

    # Either stop here (shallow) or go deeper (randomized)
    if ((current_depth < MAX_DEPTH && RANDOM % 3 != 0)); then
      generate_subtree "$subfolder" $((current_depth + 1))
    else
      generate_files "$subfolder"
    fi
  done
}

# Call this at the end of the script to print summary
print_summary() {
  echo -e "\n📝 Summary of File Creation:"
  echo "--------------------------------"
  echo "Total files created: $TOTAL_FILES_CREATED"
  echo "Total size created: $(human_readable_size $CURRENT_TOTAL_SIZE)"
}

# Simulate file aging (run after all files are created)
simulate_aging() {
  find "$ROOT" -type f | while read -r file; do
    # Pick a random age between 0 and 180 days
    age_days=$((RANDOM % 181))
    touch -d "$age_days days ago" "$file"
  done
}

# Generate a tree view report with sizes and timestamps
generate_report() {
  echo -e "\n📂 Folder Tree with File Sizes and Modified Times:"
  echo "--------------------------------------------------"
  find "$ROOT" | while read -r path; do
    indent=$(echo "$path" | sed "s|[^/]| |g" | sed "s| |  |g")
    if [ -d "$path" ]; then
      echo "${indent}📁 $(basename "$path")"
    else
      size=$(stat --printf="%s" "$path")
      mtime=$(stat --printf="%y" "$path")
      echo "${indent}📄 $(basename "$path") - $(human_readable_size $size) - Modified: $mtime"
    fi
  done
}

# Create multiple top-level folders (e.g., 5 to 10)
top_level_folders=$((RANDOM % 6 + 5))  # 5–10

for ((i=0; i<top_level_folders; i++)); do
  folder="$ROOT/top_$RANDOM"
  mkdir -p "$folder"
  generate_subtree "$folder" 1
done

echo "✅ Random folder tree created under '$ROOT'"

# Run simulation + report
simulate_aging
generate_report
print_summary
