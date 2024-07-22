#!/bin/bash
rsync -av --include='*/' --include='*.md' --exclude='*'  ../../kubernetes ./content/docs
rsync -av --include='*/' --include='*.md' --exclude='*'  ../../cicd/ansible ./content/docs

## Adding _index.md files to all directories
find ./content/docs/kubernetes -type d -exec sh -c '
for dir; do
    # Add _index.md if the directory contains .md files
    if find "$dir" -type f -name "*.md" | grep -q .; then
        if [ ! -f "$dir/_index.md" ]; then
            touch "$dir/_index.md"
        fi
    fi
done
' sh {} +

find ./content/docs/ansible -type d -exec sh -c '
for dir; do
    # Add _index.md if the directory contains .md files
    if find "$dir" -type f -name "*.md" | grep -q .; then
        if [ ! -f "$dir/_index.md" ]; then
            touch "$dir/_index.md"
        fi
    fi
done
' sh {} +


## Delete empty dirs
find ./content/docs/kubernetes -type d -empty -delete
find ./content/docs/ansible -type d -empty -delete