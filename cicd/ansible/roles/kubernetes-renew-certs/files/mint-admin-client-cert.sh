#!/bin/bash
# Mint a long-lived admin client certificate signed by the existing kubeadm CA
# and swap client-certificate-data / client-key-data into /etc/kubernetes/admin.conf.
# Required because `kubeadm certs renew all` resets the admin client cert to
# ~1 year; this makes it valid ~9 years (aligned with the 2035 CA) so kubeconfig
# copies never need redistributing.
#
# Usage: mint-admin-client-cert.sh [DAYS]
set -euo pipefail

PKI_DIR=/etc/kubernetes/pki
ADMIN_CONF=/etc/kubernetes/admin.conf
DAYS="${1:-3285}"

[ -f "$PKI_DIR/ca.crt" ] && [ -f "$PKI_DIR/ca.key" ] || { echo "CA not found in $PKI_DIR" >&2; exit 1; }
[ -f "$ADMIN_CONF" ] || { echo "admin.conf not found at $ADMIN_CONF" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

openssl genrsa -out "$TMP/admin.key" 2048 >/dev/null 2>&1
openssl req -new -key "$TMP/admin.key" \
  -subj "/CN=kubernetes-admin/O=system:masters" \
  -out "$TMP/admin.csr" >/dev/null 2>&1

cat > "$TMP/ext.cnf" <<'EOF'
extendedKeyUsage=clientAuth
keyUsage=digitalSignature,keyEncipherment
EOF

openssl x509 -req -in "$TMP/admin.csr" \
  -CA "$PKI_DIR/ca.crt" -CAkey "$PKI_DIR/ca.key" -CAcreateserial \
  -out "$TMP/admin.crt" -days "$DAYS" -sha256 -extfile "$TMP/ext.cnf" >/dev/null 2>&1

CERT="$(base64 -w0 "$TMP/admin.crt")"
KEY="$(base64 -w0 "$TMP/admin.key")"

python3 - "$ADMIN_CONF" "$CERT" "$KEY" <<'PYEOF'
import sys
path, cert, key = sys.argv[1], sys.argv[2], sys.argv[3]
lines = []
for line in open(path):
    if line.lstrip().startswith("client-certificate-data:"):
        lines.append("    client-certificate-data: %s\n" % cert)
    elif line.lstrip().startswith("client-key-data:"):
        lines.append("    client-key-data: %s\n" % key)
    else:
        lines.append(line)
open(path, "w").writelines(lines)
PYEOF

echo "admin.conf client cert minted ($DAYS days):"
openssl x509 -in "$TMP/admin.crt" -noout -subject -enddate
