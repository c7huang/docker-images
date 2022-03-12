ARG REPO_NAME
ARG CUDA_VERSION
ARG PYTHON_VERSION
ARG TORCH_VERSION

ARG MMCV_VERSION
ARG MMCLS_VERSION
ARG MMSEG_VERSION
ARG MMDET_VERSION
ARG MMDET3D_VERSION

FROM ${REPO_NAME}:cu${CUDA_VERSION}-py${PYTHON_VERSION}-torch${TORCH_VERSION}

ARG CUDA_VERSION
ARG TORCH_VERSION
ARG MMCV_VERSION
ARG MMCLS_VERSION
ARG MMSEG_VERSION
ARG MMDET_VERSION
ARG MMDET3D_VERSION

# ------------------------------------------------------------------------------
# mmdet3d
# ------------------------------------------------------------------------------

RUN pip install \
        mmcv-full==${MMCV_VERSION} \
        -f https://download.openmmlab.com/mmcv/dist/cu$(echo ${CUDA_VERSION} | tr -d \. | head -c 3)/torch${TORCH_VERSION}/index.html && \


    pip install \
        mmcls==${MMCLS_VERSION} \
        mmsegmentation==${MMSEG_VERSION} \
        mmdet==${MMDET_VERSION} \
        && \
    
    git clone https://github.com/open-mmlab/mmdetection3d.git ~/mmdet3d && \
    cd ~/mmdet3d && \
    git checkout tags/v${MMDET3D_VERSION} && \
    pip install -v . && \


# ------------------------------------------------------------------------------
# config & cleanup
# ------------------------------------------------------------------------------

    rm -rf /tmp/* ~/*
