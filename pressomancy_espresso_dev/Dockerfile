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

WORKDIR /home/stekajack

# Create and activate a virtual environment
RUN python3 -m venv /home/stekajack/venv && \
    /home/stekajack/venv/bin/pip install --upgrade pip

# Add the virtual environment to PATH
ENV PATH="/home/stekajack/venv/bin:$PATH"
ENV VIRTUAL_ENV="/home/stekajack/venv"

# Install Python packages in the virtual environment
RUN pip install --no-cache-dir \
    numpy \
    scipy \
    "Cython>=0.29.28,<3.0.12"

# Clone the custom Espresso repository
RUN git clone --branch dds_gpu_replica_field_tracking https://github.com/stekajack/espresso_patched.git espresso
COPY configs/myconfig.hpp /home/stekajack/espresso/build/myconfig.hpp
COPY patches/small_tweak.patch /home/stekajack/patches/small_tweak.patch

# Build Espresso
WORKDIR /home/stekajack/espresso
RUN git apply /home/stekajack/patches/small_tweak.patch

RUN cd build && \
    cmake -DESPRESSO_BUILD_WITH_CUDA=ON .. && \
    make -j$(nproc)

# Clone and Install Pressomancy
WORKDIR /home/stekajack
RUN git clone --branch latest_espresso_compatible_version https://github.com/stekajack/pressomancy.git && \
    cd pressomancy && \
    pip install -e .
RUN mkdir DATA_VIEW
RUN mkdir UPLOAD_VIEW

# Cleanup
RUN rm -rf /var/cache/* /tmp/* /var/log/* /usr/share/doc/*
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables for Espresso
ENV PYTHONPATH="/home/stekajack/espresso/build/src/python"
ENV ESPRESSOPATH="/home/stekajack/espresso/build/"
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# (Optional) Append environment settings to the bashrc
RUN echo 'export ESPRESSOPATH="/home/stekajack/espresso/build/"' >> /home/stekajack/.bashrc

# Keep the container running
ENTRYPOINT ["/bin/bash", "-c", "tail -f /dev/null"]