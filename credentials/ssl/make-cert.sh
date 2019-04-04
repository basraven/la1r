set -e

if [ -z "$1" ]; then
  hostname="$HOSTNAME"
else
  hostname="$1"
fi

local_openssl_config="
[ req ]
prompt = no
distinguished_name = req_distinguished_name
x509_extensions = san_self_signed
[ req_distinguished_name ]
CN=$hostname
[ san_self_signed ]
subjectAltName = DNS:$hostname, DNS:www.$hostname
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = CA:true
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment, keyCertSign, cRLSign
extendedKeyUsage = serverAuth, clientAuth, timeStamping
"

openssl req \
  -newkey rsa:2048 -nodes \
  -keyout "$hostname.key" \
  -sha256 -days 3650 \
  -config <(echo "$local_openssl_config") \
  -out "$hostname.csr"


# Show unsigned
openssl req -in $hostname.csr -noout -text

openssl x509 -req -in $hostname.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out $hostname.crt -days 500 -sha256

# Show signed
openssl x509 -in $hostname.crt -text -noout

kubectl create secret generic torrent-cert --namespace kube-system --from-file=tls.crt=/credentials/ssl/$hostname.crt --from-file=tls.key=/credentials/ssl/$hostname.key

kubectl -n kube-system create secret tls torrent-cert --key=/credentials/ssl/$hostname.key --cert=/credentials/ssl/$hostname.crt