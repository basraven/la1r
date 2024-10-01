#!/bin/bash
GoVersion=1.22
docker run -v $PWD:/app -w /app -it golang:$GoVersion-alpine sh