# Running immich on Cuda (remote host with WSL2)
1. Install Cuda on WSL by following https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=deb_local and if that doesn't work, then: https://docs.nvidia.com/cuda/wsl-user-guide/index.html#cuda-support-for-wsl-2
2. On the host, go to docker engine configuration and add:
   ```json\
   "runtimes":{
        "nvidia":{
            "path":"/usr/bin/nvidia-container-runtime",
            "runtimeArgs":[
                
            ]
        }
    }
   ```
3. Now you should be able to run the following examples:
   1. ```sudo docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi ```
   2. ```sudo docker run --rm --gpus all nvcr.io/nvidia/k8s/cuda-sample:nbody nbody -gpu -benchmark```
   3. ```sudo docker run --rm --gpus all nvcr.io/nvidia/k8s/cuda-sample:nbody nbody -gpu -benchmark -numbodies=1000000```
4. Run ```./machine-learning-docker.sh``` on wsl2