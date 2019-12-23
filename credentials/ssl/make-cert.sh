set -e
path_prefix="/credentials/ssl"

if [ "$1" == "root" ]
  then 
  echo "### Creating root cert instead of client cert:"
  # Create Root key
	openssl genrsa -out rootCA.key 2048
	# Self sign root key
	openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem
  exit 0
fi


if [ -z "$1" ]; then
  HOSTNAME="$HOSTNAME"
else
  HOSTNAME="$1"
fi

suffix=".bas"
SHORTNAME=${HOSTNAME%"$suffix"}
echo "making cert for $SHORTNAME with url $HOSTNAME"

local_openssl_config="
[ req ]
prompt = no
default_bits = 2048
default_md = sha256
distinguished_name = dn

[dn]
C=NL
ST=Amsterdam
OU=Raven
CN=$HOSTNAME
"

v3ext="
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $HOSTNAME
"


openssl req -new -sha256 -nodes -out $HOSTNAME.csr -newkey rsa:2048 -keyout $HOSTNAME.key -config <(echo "$local_openssl_config")
openssl x509 -req -in $HOSTNAME.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out $HOSTNAME.crt -days 3650 -sha256 -extfile <(echo "$v3ext")


kubectl -n kube-system delete secrets $SHORTNAME-cert || echo "No existing secret found"

kubectl create secret generic $SHORTNAME-cert --namespace kube-system --from-file=tls.crt=/credentials/ssl/$HOSTNAME.crt --from-file=tls.key=/credentials/ssl/$HOSTNAME.key
