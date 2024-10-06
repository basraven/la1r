#!/bin/bash

 kubectl annotate --field-manager=flux-client-side-apply --overwrite  receiver/flux-system  reconcile.fluxcd.io/requestedAt="$(date +%s)"