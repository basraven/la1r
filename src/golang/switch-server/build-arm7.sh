#!/bin/bash
GoVersion=1.22
docker run -v $PWD:/app -w /app/cmd/switch-server -e GOOS=linux -e GOARCH=arm -e GOARM=7 -it golang:$GoVersion-alpine go build -v -o ../../bin/switch-server-arm7