#!/bin/bash
docker run -v $PWD:/app -w /app/cmd/switch-server -e GOOS=linux -e GOARCH=amd64 -it golang:1.20-alpine go build -v -o ../../bin/switch-server-amd64