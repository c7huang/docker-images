ARG REPO
ARG BASE

FROM ${REPO}:${BASE}

ARG MMCV_VERSION
ARG MMSEG_VERSION
ARG MMDET_VERSION
ARG MMDET3D_VERSION

# ------------------------------------------------------------------------------
# mmdet3d
# ------------------------------------------------------------------------------

RUN export CU_VERSION=$(echo ${CUDA_VERSION%.*} | tr -d \.) && \
    export TORCH_VERSION=$(python -c "import torch; print(torch.__version__)") && \
    export TORCH_VERSION=${TORCH_VERSION%.*} && \
    pip install \
        mmcv-full==${MMCV_VERSION} \
        -f https://download.openmmlab.com/mmcv/dist/cu${CU_VERSION}/torch${TORCH_VERSION}/index.html && \


    pip install \
        open3d \
        mmsegmentation==${MMSEG_VERSION} \
        mmdet==${MMDET_VERSION} \
        mmdet3d==${MMDET3D_VERSION} \
        && \

# ------------------------------------------------------------------------------
# config & cleanup
# ------------------------------------------------------------------------------

    rm -rf /tmp/* ~/*
