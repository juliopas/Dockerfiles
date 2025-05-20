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
    git \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libosmesa6-dev \
    ffmpeg && \
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
    pyOpenGL \
    tqdm

# # Clone and build VTK from source
# RUN git clone --branch master https://gitlab.kitware.com/vtk/vtk.git && \
#     mkdir vtk-build && cd vtk-build && \
#     cmake ../vtk -G Ninja \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DVTK_WRAP_PYTHON=ON \
#     -DVTK_PYTHON_VERSION=3 \
#     -DVTK_GROUP_ENABLE_Qt=NO && \
#     ninja && \
#     ninja install
# # Link VTK to the virtual environment
# RUN ln -s /usr/local/lib/python3.10/site-packages/vtk /home/julio/venv/lib/python3.10/site-packages/

# Clone the custom Espresso repository
RUN git clone --branch sw_beta_MPI_wip https://github.com/stekajack/espresso_patched.git espresso

# Install requirements from requirements.txt
# RUN pip install --no-cache-dir -r /home/julio/espresso/requirements.txt 

# Build Espresso
WORKDIR /home/julio/espresso
RUN mkdir build && cd build && \
    cmake .. -DESPRESSO_BUILD_WITH_CUDA=OFF -DESPRESSO_BUILD_WITH_NLOPT=ON && \
    make -j$(nproc)

# Ensure certain Espresso features (not working)
# COPY choose_features.sh /home/julio/choose_features.sh
# RUN chmod +x /home/julio/choose_features.sh

# RUN /home/julio/choose_features.sh LB_BOUNDARIES LB_BOUNDARIES_GPU LENNARD_JONES

# Clone and Install Pressomancy
WORKDIR /home/julio
RUN git clone --branch MAE-bunch-of-springs https://github.com/juliopas/pressomancy.git && \
    cd pressomancy && \
    pip install -e .

# Make working directories
RUN mkdir DATA
RUN mkdir SCRIPTS

# Cleanup
RUN rm -rf /var/cache/* /tmp/* /var/log/* /usr/share/doc/*
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables for Espresso
ENV PYTHONPATH="/home/julio/espresso/build/src/python"
ENV ESPRESSOPATH="/home/julio/espresso/build/"

# (Optional) Append environment settings to the bashrc
RUN echo 'export ESPRESSOPATH="/home/julio/espresso/build/"' >> /home/julio/.bashrc

# Ensure the final user has full control of its home
RUN chown -R julio:julio /home/julio

# Switch to the non-root user for runtime
USER julio

# Keep the container running
ENTRYPOINT ["/bin/bash", "-c", "tail -f /dev/null"]