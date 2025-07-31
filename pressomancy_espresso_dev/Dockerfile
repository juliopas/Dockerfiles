# Base image
FROM ubuntu:24.04

# Set non-interactive frontend to suppress prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    python3-venv \
    python3-dev \
    python3-pip \
    openmpi-bin \
    libboost-all-dev \
    libfftw3-dev \
    libfftw3-mpi-dev \
    nvidia-cuda-toolkit \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/julio

# Create and activate a virtual environment
RUN python3 -m venv /home/julio/venv && \
    /home/julio/venv/bin/pip install --upgrade pip

# Add the virtual environment to PATH
ENV PATH="/home/julio/venv/bin:$PATH"
ENV VIRTUAL_ENV="/home/julio/venv"

# Install Python packages in the virtual environment
RUN pip install --no-cache-dir \
    numpy \
    scipy \
    "Cython>=0.29.28,<3.0.12" \
    tqdm

# Clone the custom Espresso repository
RUN git clone --branch dds_gpu_replica_field_tracking https://github.com/stekajack/espresso_patched.git espresso
COPY configs/myconfig.hpp /home/julio/espresso/build/myconfig.hpp
COPY patches/small_tweak.patch /home/julio/patches/small_tweak.patch

# Build Espresso
WORKDIR /home/julio/espresso
RUN git apply /home/julio/patches/small_tweak.patch

RUN cd build && \
    cmake -DESPRESSO_BUILD_WITH_CUDA=ON .. && \
    make -j$(nproc)

# Clone and Install Pressomancy
WORKDIR /home/julio
RUN git clone --branch dev_MAE-BoS https://github.com/juliopas/pressomancy.git && \
    cd pressomancy && \
    pip install -e .
RUN mkdir DATA
RUN mkdir SCRIPTS

# Cleanup
RUN rm -rf /var/cache/* /tmp/* /var/log/* /usr/share/doc/*
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables for Espresso
ENV PYTHONPATH="/home/julio/espresso/build/src/python"
ENV ESPRESSOPATH="/home/julio/espresso/build/"
ENV PYPRESSO="/home/julio/espresso/build/pypresso"
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# (Optional) Append environment settings to the bashrc
RUN echo 'export ESPRESSOPATH="/home/julio/espresso/build/"' >> /home/julio/.bashrc

# Keep the container running
ENTRYPOINT ["/bin/bash", "-c", "tail -f /dev/null"]
