ARG REPO
ARG BASE

FROM ${REPO}:${BASE}

ARG TORCH_VERSION
ARG TORCHVISION_VERSION
ARG TORCHAUDIO_VERSION

# ------------------------------------------------------------------------------
# PyTorch
# https://pytorch.org/get-started/locally/
# ------------------------------------------------------------------------------

RUN conda install \
        pytorch=${TORCH_VERSION} \
        torchvision=${TORCHVISION_VERSION} \
        torchaudio=${TORCHAUDIO_VERSION} \
        cudatoolkit=${CUDA_VERSION%.*} \
        -c pytorch -c nvidia \
        && \
    conda install \
        skorch \
        pytorch-lightning \
        -c conda-forge \
        && \
    conda install tensorboard && \

# ------------------------------------------------------------------------------
# config & cleanup
# ------------------------------------------------------------------------------

    rm -rf /tmp/* ~/*
