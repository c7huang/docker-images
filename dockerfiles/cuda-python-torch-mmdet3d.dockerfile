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
        && \
    
    git clone --depth=1 --single-branch --recursive --branch v${MMDET3D_VERSION} \
    https://github.com/open-mmlab/mmdetection3d.git ~/mmdet3d && \
    pip install -v ~/mmdet3d && \


# ------------------------------------------------------------------------------
# config & cleanup
# ------------------------------------------------------------------------------

    rm -rf /tmp/* ~/*
