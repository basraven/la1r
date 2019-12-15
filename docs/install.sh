#!/bin/sh
apk add git gcc musl-dev g++
git clone https://github.com/gohugoio/hugo.git hugo-src
cd hugo-src
go install --tags extended