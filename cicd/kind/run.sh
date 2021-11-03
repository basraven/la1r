kind create cluster --name la1r --config kind-configs/la1r.yml

kubectl taint nodes --all node-role.kubernetes.io/master-