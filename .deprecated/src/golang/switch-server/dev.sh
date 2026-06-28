#!/bin/bash
GoVersion=1.23
docker run -v $PWD:/app -w /app -it golang:$GoVersion-alpine sh