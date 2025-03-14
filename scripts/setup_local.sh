#!/bin/bash
set -e

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Setting up local environment for macOS..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Please install Homebrew first:"
        echo "https://brew.sh/"
        exit 1
    fi
    
    # Install dependencies via Homebrew
    brew install \
        cmake \
        boost \
        eigen \
        freeimage \
        glew \
        qt@5 \
        glog \
        gflags \
        ceres-solver \
        cgal \
        python

    # Add Qt to PATH if needed
    export PATH="$(brew --prefix qt@5)/bin:$PATH"
    echo 'export PATH="$(brew --prefix qt@5)/bin:$PATH"' >> ~/.bash_profile
    
    # Install PyTorch for Metal
    pip3 install torch torchvision torchaudio
    
    echo "macOS environment setup complete."
    echo "Note: Metal support is enabled by default on Apple Silicon."

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Setting up local environment for Linux..."
    
    # Ubuntu/Debian
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y \
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
            python3-dev \
            python3-pip

    # Fedora/RHEL/CentOS
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y \
            gcc-c++ \
            cmake \
            git \
            boost-devel \
            freeimage-devel \
            glog-devel \
            gflags-devel \
            glew-devel \
            qt5-qtbase-devel \
            CGAL-devel \
            ceres-solver-devel \
            python3-devel \
            python3-pip
    
    # Arch Linux
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm \
            base-devel \
            cmake \
            git \
            boost \
            freeimage \
            glog \
            gflags \
            glew \
            qt5-base \
            cgal \
            ceres-solver \
            python \
            python-pip
    else
        echo "Unsupported Linux distribution. Please install dependencies manually."
        exit 1
    fi
    
    # Check for NVIDIA GPU
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA GPU detected. Installing PyTorch with CUDA support..."
        pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    else
        echo "No NVIDIA GPU detected. Installing PyTorch CPU version..."
        pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    fi
    
    echo "Linux environment setup complete."

elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "Setting up local environment for Windows..."
    echo "For Windows, we recommend using vcpkg to install dependencies:"
    echo "1. Install Visual Studio 2019 or later with C++ development tools"
    echo "2. Install vcpkg (https://github.com/microsoft/vcpkg)"
    echo "3. Run the following commands:"
    echo "   vcpkg install boost:x64-windows eigen3:x64-windows freeimage:x64-windows"
    echo "   vcpkg install glew:x64-windows qt5:x64-windows cgal:x64-windows ceres:x64-windows"
    echo "4. Install PyTorch: pip install torch torchvision torchaudio"
else
    echo "Unsupported operating system: $OSTYPE"
    exit 1
fi

# Install other Python dependencies
pip3 install numpy scipy matplotlib opencv-python tqdm

# Check for submodules and initialize/update them if needed
if [ ! -d "colmap" ]; then
    echo "Initializing and updating submodules..."
    git submodule update --init --recursive
else
    echo "Submodules already present."
fi

# Download pre-trained models
echo "Downloading pre-trained models..."
python3 scripts/download_models.py

echo "Environment setup complete!"
echo "Next steps:"
echo "1. Run './scripts/build.sh' to build the project"
echo "2. Run './scripts/run.sh --help' to see available options"