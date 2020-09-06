KUBE_NAMESPACE="dns"
KUBE_SA_NAME="consul-k8s"
KUBE_DEPLOY_SECRET_NAME=`kubectl -n $KUBE_NAMESPACE get sa $KUBE_SA_NAME -o jsonpath='{.secrets[0].name}'`
#KUBE_API_EP=`kubectl get ep -o jsonpath='{.items[0].subsets[0].addresses[0].ip}'`
KUBE_API_EP="192.168.5.100"
KUBE_API_TOKEN=`kubectl -n $KUBE_NAMESPACE get secret $KUBE_DEPLOY_SECRET_NAME -o jsonpath='{.data.token}'|base64 --decode`
KUBE_API_CA=`kubectl -n $KUBE_NAMESPACE get secret $KUBE_DEPLOY_SECRET_NAME -o jsonpath='{.data.ca\.crt}'|base64 --decode`
echo $KUBE_API_CA > tmp.deploy.ca.crt

export KUBECONFIG=./my-new-kubeconfig
kubectl config set-cluster k8s --server=https://$KUBE_API_EP --certificate-authority=tmp.deploy.ca.crt --embed-certs=true
kubectl config set-credentials $KUBE_SA_NAME --token=$KUBE_API_TOKEN
kubectl config set-context k8s --cluster k8s --user $KUBE_SA_NAME
kubectl config use-context k8s
echo "Created $KUBECONFIG"

rm tmp.deploy.ca.crt
unset KUBECONFIG