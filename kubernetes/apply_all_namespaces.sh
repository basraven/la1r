#!/bin/bash

# This script finds and applies all namespace.yml and namespace.yaml files
# within the subdirectories of the /kubernetes folder.

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Searching for namespace definitions in $SCRIPT_DIR..."

# Find all namespace definition files
mapfile -d $'\0' files < <(find "$SCRIPT_DIR" -type f \( -name "namespace.yml" -o -name "namespace.yaml" \) -print0)

if [ ${#files[@]} -eq 0 ]; then
    echo "No namespace files found."
    exit 0
fi

# Get existing namespaces
existing_namespaces=$(kubectl get ns --no-headers -o custom-columns=":metadata.name")
existing_count=$(echo "$existing_namespaces" | wc -l)

new_namespaces_to_apply=()

# Check which namespaces are new
for file in "${files[@]}"; do
    # Extract namespace name from YAML. Assumes 'name:' is on its own line under 'metadata:'.
    namespace_name=$(grep -A 1 "metadata:" "$file" | grep "name:" | awk '{print $2}')
    if ! echo "$existing_namespaces" | grep -q -w "$namespace_name"; then
        new_namespaces_to_apply+=("$file")
    fi
done

new_count=${#new_namespaces_to_apply[@]}

# Confirmation prompt
if [ $new_count -gt 0 ]; then
    echo
    echo "Found $new_count new namespace(s) to create."
    echo "There are currently $existing_count existing namespace(s) in the cluster."
    read -p "Do you want to apply these new namespaces? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting."
        exit 1
    fi

    # Apply only the new namespaces
    for file in "${new_namespaces_to_apply[@]}"; do
        echo "Applying: $file"
        kubectl apply -f "$file"
    done
else
    echo "All found namespaces already exist in the cluster. Nothing to do."
fi

echo "All found namespaces have been applied."
