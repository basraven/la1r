#!/usr/bin/env bash
#
# Enable "Fail Downloads" (Executables + Potentially Dangerous) on EVERY indexer
# in Sonarr and Radarr.
#
# Why: indexers such as 1337x regularly carry fake "video" releases that are
# actually a single .exe/.scr/.vbs (e.g. "MobLand S02E05 1080p HD h264 ETHEL.exe").
# When this option is set, the *arr app marks the completed download as FAILED,
# removes it from qBittorrent and BLOCKLISTS the release, so it is never grabbed
# again -- instead of looping on the same malware release every week.
#
# Executables list (built in, cannot be edited):  .bat .cmd .exe .sh
# Potentially Dangerous list (built in):          .arj .lnk .lzh .ps1 .scr .vbs .zipx
#
# This is stored in the app DB on the PVC (not in any manifest), so re-run it
# after a DB/config reset or after adding new indexers. Idempotent.
#
# See kubernetes/torrent/_index.md -> "Blocking executable/malware downloads".
#
# Usage: ./enable-fail-downloads.sh
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube-la1r/config}"
NAMESPACE="${NAMESPACE:-torrent}"
FAIL_DOWNLOADS='[0,1]'   # 0 = Executables, 1 = Potentially Dangerous

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

get_api_key() {
  kubectl exec -n "$NAMESPACE" "deploy/$1" -- cat /config/config.xml 2>/dev/null \
    | sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p'
}

get_indexers() {
  kubectl exec -n "$NAMESPACE" "deploy/$1" -- \
    sh -c "curl -s -H 'X-Api-Key: $2' 'http://127.0.0.1:$3/api/v3/indexer'"
}

put_indexer() {
  kubectl exec -i -n "$NAMESPACE" "deploy/$1" -- \
    sh -c "curl -s -o /dev/null -w '%{http_code}' -X PUT \
      -H 'X-Api-Key: $2' -H 'Content-Type: application/json' \
      --data-binary @- 'http://127.0.0.1:$3/api/v3/indexer/$4?forceSave=true'"
}

process_app() {
  local app=$1 port=$2 key indexers id name before payload code
  key=$(get_api_key "$app")
  if [[ -z "$key" ]]; then
    echo "=== $app: not reachable / no API key (skipping) ==="
    return
  fi
  indexers=$(get_indexers "$app" "$key" "$port")
  echo "=== $app ($(jq 'length' <<<"$indexers") indexers) ==="
  while read -r id; do
    name=$(jq -r --argjson id "$id" '.[]|select(.id==$id)|.name' <<<"$indexers")
    before=$(jq -c --argjson id "$id" \
      '.[]|select(.id==$id)|.fields[]|select(.name=="failDownloads")|.value' <<<"$indexers")
    if [[ "$before" == "$FAIL_DOWNLOADS" ]]; then
      echo "  [$id] $name: already $FAIL_DOWNLOADS"
      continue
    fi
    payload=$(jq -c --argjson id "$id" --argjson t "$FAIL_DOWNLOADS" \
      '.[]|select(.id==$id)|.fields|=map(if .name=="failDownloads" then .value=$t else . end)' <<<"$indexers")
    code=$(printf '%s' "$payload" | put_indexer "$app" "$key" "$port" "$id")
    echo "  [$id] $name: $before -> $FAIL_DOWNLOADS (HTTP $code)"
  done < <(jq -r '.[].id' <<<"$indexers")
}

process_app sonarr 8989
process_app radarr 7878
