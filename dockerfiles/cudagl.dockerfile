ARG CUDA_VERSION
ARG UBUNTU_VERSION

# Use cudagl to support OpenGL applications in docker (e.g., Open3D)
FROM nvidia/cudagl:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}
ENV LANG C.UTF-8

ARG CUDNN_VERSION
ARG CMAKE_VERSION

RUN apt-get update -q && \

# ------------------------------------------------------------------------------
# tools
# ------------------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        git \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        mercurial \
        openssh-client \
        procps \
        subversion \
        wget \
        curl \
        vim \
        unzip \
        unrar \
        build-essential \
        software-properties-common \
        libgl1 \
        && \

# ------------------------------------------------------------------------------
# CUDNN
# https://gitlab.com/nvidia/container-images/cuda
# ------------------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends \
        libcudnn${CUDNN_VERSION}=*-1+cuda${CUDA_VERSION%.*} \
        libcudnn${CUDNN_VERSION}-dev=*-1+cuda${CUDA_VERSION%.*} \
        && \
    apt-mark hold libcudnn${CUDNN_VERSION} && \

# ------------------------------------------------------------------------------
# cmake
# https://cmake.org/download/
# ------------------------------------------------------------------------------

    wget -O ~/cmake.sh -q \
        https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh && \
    bash ~/cmake.sh --skip-license --prefix=/usr --exclude-subdir && \

# ------------------------------------------------------------------------------
# nodejs
# https://github.com/nodesource/distributions/blob/master/README.md
# ------------------------------------------------------------------------------

    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends nodejs && \

# ------------------------------------------------------------------------------
# config & cleanup
# ------------------------------------------------------------------------------

    ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*
