cd ..
docker run --rm -it --name la1r -p 8313:8313 --workdir /go/src/documentation/src -v $pwd/:/go/src -it golang /bin/bash
cd .\documentation
# /go/src/documentation/install-hugo.sh ; hugo server --bind '0.0.0.0' --port 8313 --navigateToChanged --disableFastRender --forceSyncStatic