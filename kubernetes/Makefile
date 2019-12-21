.PHONY: all
all: network-overlay dashboard config  traefik

.PHONY: local
local: dashboard nextcloud

# Prefix all commands with - to ignore errors (already exists errors)

.PHONY: network-overlay
network-overlay:
	# - curl -sSL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml | sed "s/amd64/arm/g" | kubectl create -f -  && exit 0
	# - kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
	- kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

	- kubectl apply -f https://raw.githubusercontent.com/weaveworks/scope/master/examples/k8s/ns.yaml
	- kubectl apply -f https://raw.githubusercontent.com/weaveworks/scope/master/examples/k8s/cluster-role-binding.yaml
	- kubectl apply -f https://raw.githubusercontent.com/weaveworks/scope/master/examples/k8s/cluster-role.yaml
	- kubectl apply -f https://raw.githubusercontent.com/weaveworks/scope/master/examples/k8s/deploy.yaml
	# - kubectl apply -f https://raw.githubusercontent.com/weaveworks/scope/master/examples/k8s/ds.yaml # untaint for pi
	- kubectl apply -f kube-system/weave-scope/ds.yaml
	- kubectl apply -f https://raw.githubusercontent.com/weaveworks/scope/master/examples/k8s/probe-deploy.yaml
	- kubectl apply -f https://raw.githubusercontent.com/weaveworks/scope/master/examples/k8s/psp.yaml
	- kubectl apply -f https://raw.githubusercontent.com/weaveworks/scope/master/examples/k8s/sa.yaml
	- kubectl apply -f https://raw.githubusercontent.com/weaveworks/scope/master/examples/k8s/svc.yaml
	- kubectl apply -f kube-system/weave-scope/scope-ingress.yam
	
.PHONY: dashboard
dashboard:
	- kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml

.PHONY: config 
config: 
	- kubectl taint nodes big-raver node-role.kubernetes.io/master-
	# - kubectl taint nodes raspi1 pi=true:NoSchedule
	# - kubectl taint nodes raspi2 pi=true:NoSchedule
	# - kubectl taint nodes carrot carrot=true:NoSchedule
	# - kubectl label nodes big-raver disktype=hdd
	# - kubectl label nodes raspi1 disktype=hdd
	# - kubectl label nodes raspi2 disktype=hdd
	# - kubectl label node raspi1 node-role.kubernetes.io/worker=worker
	# - kubectl label node raspi2 node-role.kubernetes.io/worker=worker
	# - kubectl label node carrot node-role.kubernetes.io/worker=worker


.PHONY: traefik
traefik:
	- kubectl apply -f kube-system/traefik/traefik.yaml
	- kubectl apply -f kube-system/traefik/traefik-rbac.yaml
	# - kubectl create secret generic traefik-cert --namespace kube-system --from-file=main.crt=../credentials/ssl/cloud.bas.crt --from-file=main.key=../credentials/ssl/cloud.bas.key
	# - kubectl create configmap traefik-conf --namespace kube-system --from-file=kube-system/traefik/traefik.toml
	# - kubectl apply -f kube-system/traefik/traefik.yaml

.PHONY: nextcloud
nextcloud:
	- kubectl apply -f nextcloud/namespace.yaml
	- kubectl apply -f nextcloud/dbsecret.yaml
	- kubectl apply -f nextcloud/mariadb-pv.yaml
	- kubectl apply -f nextcloud/mariadb.yaml
	- kubectl apply -f nextcloud/redis-pv.yaml
	- kubectl apply -f nextcloud/redis.yaml
	- kubectl apply -f nextcloud/nextcloud-pv.yaml
	- kubectl apply -f nextcloud/nextcloud.yaml

.PHONY: backup
backup:
	- kubectl apply -f backup/backup-pv.yaml
	- kubectl apply -f backup/backup.yaml

.PHONY: unbackup
unbackup:
	- kubectl delete configmap backup-script --namespace backup
	- kubectl delete -f backup/backup-nextcloud.yaml
	- kubectl delete -f backup/backup-pvc.yaml
	- kubectl delete -f backup/backup-pv.yaml

	
.PHONY: qbittorrent
qbittorrent:
	- kubectl create secret generic goose-credentials --namespace torrent --from-file=/credentials/ovpn/login.conf --from-file=cert1.conf=/credentials/ovpn/ro-10.conf --from-file=cert2.conf=/credentials/ovpn/hu-2.conf
	- kubectl apply -f qbittorrent

# Refresh claimToken from https://www.plex.tv/claim/
.PHONY: plex
plex:
	- kubectl apply -f torrent/plex/plex-pv.yaml
	- kubectl apply -f torrent/plex/plex.yaml

.PHONY: unplex
unplex:
	- kubectl delete -f torrent/plex/plex-pv.yaml
	- kubectl delete -f torrent/plex/plex.yaml

.PHONY: ssl-certs
ssl-certs:
	# Source: https://gist.github.com/fntlnz/cf14feb5a46b2eda428e000157447309
	
	# Create rootCA
	/credentials/ssl/make-cert.sh root
	
	# Create client cert
	/credentials/ssl/make-cert.sh cloud.bas

	kubectl create secret generic nextcloud-ssl --namespace nextcloud --from-file=tls.crt=/credentials/ssl/cloud.bas.crt --from-file=tls.key=/credentials/ssl/cloud.bas.key 

###############################################################
######## Deprecated, not in current cluster ###################
###############################################################


.PHONY: faas
faas:
	- kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
	- git clone https://github.com/openfaas/faas-netes /tmp/faas-netes
	- kubectl apply -f /tmp/faas-netes/yaml_armhf
	- rm -rf /tmp/faas-netes

# TODO: replace heapster with metrics-server
.PHONY: dashboard-metrics
dashboard-metrics:
	- kubectl apply -f maintenance/heapster/heapster.yaml

.PHONY: prometheus
prometheus:
	cp -rf helm/helm-custom/stable/prometheus-operator/* helm/helm/stable/prometheus-operator/
	helm install stable/prometheus-operator --tiller-namespace tiller --name prometheus-operator --namespace maintenance
	- kubectl apply -f maintenance/prometheus/prometheus-ingress.yaml

.PHONY: unprometheus
unprometheus:
	- helm del --purge prometheus-operator --tiller-namespace tiller
	- kubectl delete -f maintenance/prometheus/prometheus-ingress.yaml
	- kubectl delete crd prometheuses.monitoring.coreos.com
	- kubectl delete crd prometheusrules.monitoring.coreos.com
	- kubectl delete crd servicemonitors.monitoring.coreos.com
	- kubectl delete crd alertmanagers.monitoring.coreos.com

.PHONY: helm
helm:
	- kubectl apply -f namespaces/tiller.yaml
	- kubectl create serviceaccount --namespace tiller tiller
	- kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=tiller:tiller
	- kubectl patch deploy --namespace tiller tiller-deploy -p'{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
	- rm -rf /root/.helm
	- helm init --tiller-namespace tiller