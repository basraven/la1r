# Running Immich with CUDA on Remote WSL2 Host

This document provides instructions for enabling GPU acceleration with CUDA for Immich on a remote host using Windows Subsystem for Linux 2 (WSL2).

## Overview
Immich can leverage GPU acceleration for faster photo and video processing. When running on a remote WSL2 host, additional steps are required to install CUDA, configure Docker, and verify GPU access for containers.

## Key Components
- **CUDA Installation**: Install NVIDIA CUDA drivers and toolkit in WSL2.
- **Docker Runtime Configuration**: Enable the `nvidia` runtime in Docker for GPU access.
- **Test Containers**: Run sample containers to verify GPU functionality.
- **Machine Learning Script**: Use the provided script for ML workloads.

## Usage
1. Install CUDA on WSL2 by following the official [NVIDIA CUDA Downloads](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=deb_local) or, if needed, [WSL2 CUDA Guide](https://docs.nvidia.com/cuda/wsl-user-guide/index.html#cuda-support-for-wsl-2).
2. Update Docker engine configuration on the host:
   ```json
   "runtimes":{
        "nvidia":{
            "path":"/usr/bin/nvidia-container-runtime",
            "runtimeArgs":[]
        }
    }
   ```
3. Test GPU access with the following commands:
   - `sudo docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi`
   - `sudo docker run --rm --gpus all nvcr.io/nvidia/k8s/cuda-sample:nbody nbody -gpu -benchmark`
   - `sudo docker run --rm --gpus all nvcr.io/nvidia/k8s/cuda-sample:nbody nbody -gpu -benchmark -numbodies=1000000`
4. Run the machine learning setup script:
   ```bash
   ./machine-learning-docker.sh
   ```

## References
- [NVIDIA CUDA for WSL2](https://docs.nvidia.com/cuda/wsl-user-guide/index.html)
- [Immich Documentation](https://immich.app/docs/)