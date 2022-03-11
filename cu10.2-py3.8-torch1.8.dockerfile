FROM c7huang/devel:cu10.2-py3.8

# LTS Torch version: https://pytorch.org/get-started/locally/
ARG TORCH_VERSION=1.8
# Torchvision version: https://github.com/pytorch/vision
ARG TORCHVISION_VERSION=0.9
# Torchaudio version: https://github.com/pytorch/audio
ARG TORCHAUDIO_VERSION=0.8

# ------------------------------------------------------------------------------
# PyTorch
# https://pytorch.org/get-started/locally/
# ------------------------------------------------------------------------------

RUN conda install -c pytorch-lts \
        pytorch=${TORCH_VERSION} \
        torchvision=${TORCHVISION_VERSION} \
        torchaudio=${TORCHAUDIO_VERSION} \
        cudatoolkit=$(echo ${CU_VERSION} | tr -d '\.') \
        && \
    conda install -c conda-forge \
        skorch \
        pytorch-lightning \
        && \

# ------------------------------------------------------------------------------
# config & cleanup
# ------------------------------------------------------------------------------

    rm -rf /tmp/* ~/*
