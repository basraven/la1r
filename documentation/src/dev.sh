#!/bin/bash
rm -rf public && rm -rf resources/_gen
hugo server --minify --theme hugo-book  --disableFastRender --environment development
