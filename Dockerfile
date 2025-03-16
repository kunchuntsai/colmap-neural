# Use Ubuntu base image compatible with Apple Silicon
FROM --platform=linux/arm64 ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libboost-all-dev \
    libfreeimage-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libceres-dev \
    libsuitesparse-dev \
    python3-dev \
    python3-pip \
    wget \
    unzip \
    ninja-build \
    libatlas-base-dev \
    libeigen3-dev \
    libflann-dev \
    libsqlite3-dev \
    nano \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PyTorch (CPU version - we'll use Metal on the host machine)
RUN pip3 install --no-cache-dir torch torchvision torchaudio

# Install other Python dependencies
RUN pip3 install --no-cache-dir \
    numpy \
    scipy \
    matplotlib \
    opencv-python \
    h5py \
    tqdm

# Create a non-root user (optional but recommended)
RUN useradd -m -d /home/colmap -s /bin/bash colmap && \
    echo "colmap:colmap" | chpasswd && \
    adduser colmap sudo

# Set working directory
WORKDIR /app

# Set a default command that gives us a shell
CMD ["/bin/bash"]