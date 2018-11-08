#!/bin/bash

cp /credentials/ssh/id_rsa /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa

exec "$@"