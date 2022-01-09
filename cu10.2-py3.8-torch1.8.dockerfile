FROM c7huang/devel:cu10.2-py3.8
ENV LANG C.UTF-8

ARG MMCV_VERSION=cu102/torch1.8.0

# ------------------------------------------------------------------------------
# PyTorch
# ------------------------------------------------------------------------------

RUN conda install -c pytorch-lts \
        pytorch \
        torchvision \
        torchaudio \
        cudatoolkit=10.2 \
        && \
    conda install -c conda-forge \
        skorch \
        pytorch-lightning \
        captum \
        && \
    pip install mmcv-full \
        -f https://download.openmmlab.com/mmcv/dist/${MMCV_VERSION}/index.html  && \

# ------------------------------------------------------------------------------
# config & cleanup
# ------------------------------------------------------------------------------

    rm -rf /tmp/* ~/*
