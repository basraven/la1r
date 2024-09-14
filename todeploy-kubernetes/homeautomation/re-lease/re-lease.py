
import os
import etcd3
import kubernetes.client
from kubernetes.client.rest import ApiException
from kubernetes import config

# Get etcd credentials from the host path
etcd_ca_cert = '/etc/kubernetes/pki/etcd/ca.crt'
etcd_client_cert = '/etc/kubernetes/pki/apiserver-etcd-client.crt'
etcd_client_key = '/etc/kubernetes/pki/apiserver-etcd-client.key'

# Connect to etcd
etcd_client = etcd3.client(
    host='127.0.0.1',
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

# Use kubernetes client to get additional information
config.load_kube_config()
v1 = kubernetes.client.CoreV1Api()

print("\nListing Kubernetes resources:")
try:
    # List namespaces
    namespaces = v1.list_namespace()
    print("Namespaces:")
    for ns in namespaces.items:
        print(f"- {ns.metadata.name}")

    # List pods in default namespace
    pods = v1.list_namespaced_pod("homeautomation")
    print("\nPods in default namespace:")
    for pod in pods.items:
        print(f"- {pod.metadata.name}")
except ApiException as e:
    print(f"Error accessing Kubernetes API: {str(e)}")
