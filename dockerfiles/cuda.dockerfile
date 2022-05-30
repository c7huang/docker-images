ARG CUDA_VERSION
ARG CUDNN_VERSION
ARG UBUNTU_VERSION

FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-devel-ubuntu${UBUNTU_VERSION}
ENV LANG C.UTF-8

ARG UBUNTU_VERSION

# ------------------------------------------------------------------------------
# NVIDIA key rotation
# https://forums.developer.nvidia.com/t/notice-cuda-linux-repository-key-rotation/212771
# ------------------------------------------------------------------------------

RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(echo $UBUNTU_VERSION | tr -d \.)/x86_64/3bf863cc.pub && \
    apt-get update -q && \

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
# config & cleanup
# ------------------------------------------------------------------------------

    ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*
