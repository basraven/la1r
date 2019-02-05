#--- Source: http://clarkgrubb.com/makefile-style-guide
# MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -e -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

#--- Surpress default functions
.PHONY: create
create: ;@:
.PHONY: delete
delete: ;@:

#--- Target PHONY
# .PHONY: torrent

# coun=($(MAKECMDGOALS)  | wc -l)
# coun=1

ifneq ($(findstring $(MAKECMDGOALS), "create"),)
		echo "in create"
else
		echo "niet create" 
endif

sonarr:	
.PHONY: sonarr
	# create:
	# 	echo "cretae"
	# delete:
	# 	echo "dleete"	
	# if [[ $coun == 1 ]]; then
	# 	echo "maar een"
	# else
	# 	echo "naders"
	# fi 
	# echo $(MAKECMDGOALS)
	# - kubectl create secret generic goose-credentials --namespace torrent --from-file=/credentials/ovpn/login.conf --from-file=/credentials/ovpn/ro-10.conf
	# - kubectl create configmap qbittorrent-config --namespace torrent --from-file=qbittorrent/config/set-goose.sh
	# - kubectl apply -f qbittorrent
