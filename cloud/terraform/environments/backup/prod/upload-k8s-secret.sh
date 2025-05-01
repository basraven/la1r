#!/bin/bash

# Upload both ~/.aws/config-backup-uploader and ~/.aws/credentials-backup-uploader to kubernetes as secrets
kubectl create secret -n backup generic aws-config-backup-uploader --from-file=config=/home/basraven/.aws/config-backup-uploader --from-file=credentials=/home/basraven/.aws/credentials-backup-uploader 