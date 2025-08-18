#!/bin/bash

# This script finds and applies all namespace.yml and namespace.yaml files
# within the subdirectories of the /kubernetes folder.

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Searching for namespace definitions in $SCRIPT_DIR..."

# Find all namespace definition files
# Matches:
#  - namespace.yml / namespace.yaml
#  - namespace-*.yml / namespace-*.yaml
mapfile -d $'\0' files < <(find "$SCRIPT_DIR" -type f \
    \( -name "namespace.yml" -o -name "namespace.yaml" -o -name "namespace-*.yml" -o -name "namespace-*.yaml" \) \
    -print0)

if [ "${VERBOSE:-0}" = "1" ]; then
    echo "[DEBUG] Found ${#files[@]} candidate file(s):"
    for f in "${files[@]}"; do echo "[DEBUG]  - $f"; done
fi

if [ ${#files[@]} -eq 0 ]; then
    echo "No namespace files found."
    exit 0
fi

# Get existing namespaces
existing_namespaces=$(kubectl get ns --no-headers -o custom-columns=":metadata.name")
existing_count=$(echo "$existing_namespaces" | wc -l)

if [ "${VERBOSE:-0}" = "1" ]; then
    echo "[DEBUG] Existing namespaces (${existing_count}):"
    echo "$existing_namespaces" | sed 's/^/[DEBUG]   - /'
fi

new_namespaces_to_apply=()

# Check which namespaces are new
for file in "${files[@]}"; do
    # Only consider files where kind: Namespace exists
    if ! grep -Eq '^kind:[[:space:]]*Namespace([[:space:]]*#.*)?[[:space:]]*$' "$file"; then
        [ "${VERBOSE:-0}" = "1" ] && echo "[DEBUG] Skipping (no Namespace kind): $file"
        continue
    fi

    # Extract metadata.name robustly
    namespace_name=$(awk '
      /^metadata:[[:space:]]*$/ {inmeta=1; next}
      inmeta && /^[[:space:]]*name:[[:space:]]*/ {
        n=$0; sub(/^[[:space:]]*name:[[:space:]]*/, "", n); sub(/[[:space:]]+$/, "", n); print n; exit
      }
    ' "$file")

    if [ -z "$namespace_name" ]; then
        [ "${VERBOSE:-0}" = "1" ] && echo "[DEBUG] Skipping (no metadata.name found): $file"
        continue
    fi

    [ "${VERBOSE:-0}" = "1" ] && echo "[DEBUG] Candidate ns '$namespace_name' from $file"

    if ! echo "$existing_namespaces" | grep -q -x "$namespace_name"; then
        new_namespaces_to_apply+=("$file")
    else
        [ "${VERBOSE:-0}" = "1" ] && echo "[DEBUG] Namespace exists, skipping apply: $namespace_name"
    fi
done

new_count=${#new_namespaces_to_apply[@]}

if [ "${VERBOSE:-0}" = "1" ]; then
    echo "[DEBUG] Will apply ${new_count} file(s):"
    for f in "${new_namespaces_to_apply[@]}"; do echo "[DEBUG]   - $f"; done
fi

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
