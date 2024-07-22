#!/bin/bash
rm -rf public && rm -rf resources/_gen && content/kubernetes/*
./populate-external-docs.sh
hugo server --minify --theme hugo-book  --disableFastRender --environment development
