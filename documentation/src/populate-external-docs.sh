#!/bin/bash
rsync -av --include='*/' --include='*.md' --exclude='*'  ../../kubernetes ./content/docs
rsync -av --include='*/' --include='*.md' --exclude='*'  ../../cicd/ansible ./content/docs

## Adding _index.md files to all directories
find ./content/docs/kubernetes -type d -exec sh -c '
for dir; do
    if [ "$(find "$dir" -maxdepth 1 -type f | wc -l)" -eq 0 ]; then
    if [ ! -f "$dir/_index.md" ]; then
        touch "$dir/_index.md"
    fi
    fi
done
' sh {} +

find ./content/docs/ansible -type d -exec sh -c '
for dir; do
    if [ "$(find "$dir" -maxdepth 1 -type f | wc -l)" -eq 0 ]; then
    if [ ! -f "$dir/_index.md" ]; then
        touch "$dir/_index.md"
    fi
    fi
done
' sh {} +

## Removing empty directories
find content/docs/kubernetes -type d -depth -exec sh -c '
  for dir; do
    if [ "$(find "$dir" -maxdepth 1 -type f ! -name "_index.md" | wc -l)" -eq 0 ] && [ "$(find "$dir" -maxdepth 1 -type f -name "_index.md" | wc -l)" -eq 1 ] && [ "$(find "$dir" -mindepth 1 -type d | wc -l)" -eq 0 ]; then
      echo "Removing directory: $dir"
      rm -rf "$dir"
    fi
  done
' sh {} +

find content/docs/ansible -type d -depth -exec sh -c '
  for dir; do
    if [ "$(find "$dir" -maxdepth 1 -type f ! -name "_index.md" | wc -l)" -eq 0 ] && [ "$(find "$dir" -maxdepth 1 -type f -name "_index.md" | wc -l)" -eq 1 ] && [ "$(find "$dir" -mindepth 1 -type d | wc -l)" -eq 0 ]; then
      echo "Removing directory: $dir"
      rm -rf "$dir"
    fi
  done
' sh {} +