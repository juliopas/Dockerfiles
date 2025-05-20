# Base image
FROM ubuntu:22.04

# Set non-interactive frontend to suppress prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        ninja-build \
        python3-venv \
        python3-dev \
        python3-pip \
        openmpi-bin \
        libboost-all-dev \
        fftw3-dev \
        libfftw3-mpi-dev \
        libopenmpi3 \
        libevent-2.1-7 \
        git \
        
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up a user
RUN useradd -m -s /bin/bash julio
WORKDIR /home/julio

# Create and activate a virtual environment
RUN python3 -m venv /home/julio/venv && \
    /home/julio/venv/bin/pip install --upgrade pip setuptools wheel

# Add the virtual environment to PATH
ENV PATH="/home/julio/venv/bin:$PATH"
ENV VIRTUAL_ENV="/home/julio/venv"

# Install Python packages in the virtual environment
RUN pip install --no-cache-dir \
    numpy \
    scipy \
    cython \
    matplotlib \
    tqdm

# Clone the custom Espresso repository
RUN git clone --branch sw_beta_MPI_wip https://github.com/stekajack/espresso_patched.git espresso

# Build Espresso
WORKDIR /home/julio/espresso
RUN mkdir build && cd build && \
    cmake .. -DESPRESSO_BUILD_WITH_CUDA=OFF -DESPRESSO_BUILD_WITH_NLOPT=ON && \
    make -j$(nproc)

# Clone and Install Pressomancy
WORKDIR /home/julio
RUN git clone --branch main https://github.com/juliopas/pressomancy.git && \
    cd pressomancy && \
    pip install -e .

# Make working directories
RUN mkdir DATA

# Cleanup
RUN rm -rf /var/cache/* /tmp/* /var/log/* /usr/share/doc/*
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables for Espresso
ENV PYTHONPATH="/home/julio/espresso/build/src/python"
ENV ESPRESSOPATH="/home/julio/espresso/build"
ENV PYPRESSO="/home/julio/espresso/build/pypresso"
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# Ensure the final user has full control of its home
RUN chown -R julio:julio /home/julio

# Switch to the non-root user for runtime
USER julio

# Keep the container running
ENTRYPOINT ["/bin/bash", "-c", "tail -f /dev/null"]
