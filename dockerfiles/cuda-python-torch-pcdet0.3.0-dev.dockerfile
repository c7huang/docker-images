ARG REPO
ARG BASE

FROM ${REPO}:${BASE}

# ------------------------------------------------------------------------------
# spconv
# ------------------------------------------------------------------------------

RUN apt-get update -q && \
    DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends \
        libboost-dev \
        && \
    
    git clone -b v1.2.1 --single-branch --recursive \
        https://github.com/traveller59/spconv.git ~/spconv && \

    cd ~/spconv && \
    python setup.py bdist_wheel && \
    pip install dist/spconv-1.2.1-*.whl && \

# ------------------------------------------------------------------------------
# config & cleanup
# ------------------------------------------------------------------------------

    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*
