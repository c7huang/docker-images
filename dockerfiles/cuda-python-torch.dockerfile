ARG REPO_NAME
ARG CUDA_VERSION
ARG PYTHON_VERSION
ARG TORCH_VERSION

FROM ${REPO_NAME}:cu${CUDA_VERSION}-py${PYTHON_VERSION}

ARG CUDA_VERSION
ARG TORCH_VERSION

# ------------------------------------------------------------------------------
# PyTorch
# https://pytorch.org/get-started/locally/
# ------------------------------------------------------------------------------

RUN conda install \
        pytorch=${TORCH_VERSION} \
        torchvision \
        torchaudio \
        cudatoolkit=${CUDA_VERSION} \
        -c pytorch -c nvidia \
        && \
    conda install \
        skorch \
        pytorch-lightning \
        -c conda-forge \
        && \

# ------------------------------------------------------------------------------
# config & cleanup
# ------------------------------------------------------------------------------

    rm -rf /tmp/* ~/*
