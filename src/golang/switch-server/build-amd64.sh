#!/bin/bash
GoVersion=1.22
docker run --rm -v $PWD:/app -w /app/cmd/switch-server -e GOOS=linux -e GOARCH=amd64 -it golang:$GoVersion-alpine go build -v -o ../../bin/switch-server-amd64