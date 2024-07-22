#!/bin/bash
rm -rf public && rm -rf resources/_gen && content/kubernetes/*
rsync -av --include='*/' --include='*.md' --exclude='*'  ../../kubernetes ./content/docs/
rsync -av --include='*/' --include='*.md' --exclude='*'  ../../cicd/ansible ./content/docs/
hugo server --minify --theme hugo-book  --disableFastRender --environment development
