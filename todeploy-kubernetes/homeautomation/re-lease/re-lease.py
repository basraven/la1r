import os
import etcd3

# Get etcd credentials from the host path
etcd_ca_cert = '/etc/kubernetes/pki/etcd/ca.crt'
etcd_client_cert = '/etc/kubernetes/pki/apiserver-etcd-client.crt'
etcd_client_key = '/etc/kubernetes/pki/apiserver-etcd-client.key'

# Connect to etcd
etcd_client = etcd3.client(
    host='192.168.5.1',
    port=2379,
    ca_cert=etcd_ca_cert,
    cert_key=etcd_client_key,
    cert_cert=etcd_client_cert
)

# List some variables stored in etcd
print("Listing some variables stored in etcd:")
try:
    # Get all keys with prefix '/registry'
    for value, metadata in etcd_client.get_prefix('/registry'):
        print(f"Key: {metadata.key.decode('utf-8')}")
        print(f"Value: {value.decode('utf-8')}")
        print("---")
except Exception as e:
    print(f"Error accessing etcd: {str(e)}")

# List Kubernetes resources using etcd
print("\nListing Kubernetes resources using etcd:")
try:
    # List namespaces
    namespaces = etcd_client.get_prefix('/registry/namespaces')
    print("Namespaces:")
    for _, metadata in namespaces:
        namespace = metadata.key.decode('utf-8').split('/')[-1]
        print(f"- {namespace}")

    # List pods in homeautomation namespace
    pods = etcd_client.get_prefix('/registry/pods/homeautomation')
    print("\nPods in homeautomation namespace:")
    for _, metadata in pods:
        pod = metadata.key.decode('utf-8').split('/')[-1]
        print(f"- {pod}")
except Exception as e:
    print(f"Error accessing etcd: {str(e)}")
