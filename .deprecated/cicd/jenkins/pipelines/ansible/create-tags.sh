#!/bin/bash
function buildTagsLine {
  export tags=""
  prefix="tag_"
  while IFS='=' read -r name value ; do
    if [[ $name == *'tag_'* ]]; then
      if [ ${!name} = "true" ]; then
        export tags="$tags${name#${prefix}},"
      fi
    fi
  done < <(env)
  export tags=${tags::-1} # remove the last ,
}

buildTagsLine
echo $tags
