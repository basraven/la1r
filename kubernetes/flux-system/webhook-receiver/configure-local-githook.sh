#!/bin/bash 
# check if the .git directory exists
if [ ! -d .git ]; then
    echo "Error: .git directory not found. Please run this script from the root of your git repository."
    exit 1
fi

# Create a new file named "post-push" in the .git/hooks directory
touch .git/hooks/post-push

chmod +x .git/hooks/post-push
echo '#!/bin/bash
sleep 5
kubernetes/flux-system/webhook-receiver/trigger-flux.sh
' > .git/hooks/post-push
