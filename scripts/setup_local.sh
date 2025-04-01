#!/bin/bash
# scripts/setup_local.sh

set -e

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$PROJECT_ROOT/models"

echo "🚀 Setting up COLMAP Neural Enhancement environment"
echo "===================================================="

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    echo "🐧 Detected Linux operating system"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    echo "🍎 Detected macOS operating system"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
    echo "🪟 Detected Windows operating system"
else
    echo "❌ Unsupported operating system: $OSTYPE"
    exit 1
fi

# Check for M-series Mac
if [[ "$OS" == "macos" ]]; then
    if [[ $(uname -m) == "arm64" ]]; then
        echo "🍎 Detected Apple Silicon (M-series) Mac"
        IS_APPLE_SILICON=true
    else
        echo "🍎 Detected Intel Mac"
        IS_APPLE_SILICON=false
    fi
fi

# Install system dependencies based on OS
install_dependencies() {
    echo "📦 Installing system dependencies..."
    
    if [[ "$OS" == "linux" ]]; then
        # Check if we can use apt (Ubuntu/Debian)
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y \
                build-essential \
                cmake \
                git \
                libboost-all-dev \
                libeigen3-dev \
                libgflags-dev \
                libgoogle-glog-dev \
                libsqlite3-dev \
                libfreeimage-dev \
                libcgal-dev \
                libceres-dev \
                libflann-dev \
                libatlas-base-dev \
                libsuitesparse-dev \
                python3-dev \
                python3-pip
            
            # Check for NVIDIA GPU
            if command -v nvidia-smi &> /dev/null; then
                echo "🖥️ NVIDIA GPU detected, installing CUDA support"
                # Install CUDA if not present
                if ! command -v nvcc &> /dev/null; then
                    echo "⚠️ CUDA not found, please install CUDA 11.7+ manually"
                    echo "   Visit: https://developer.nvidia.com/cuda-downloads"
                fi
            else
                echo "⚠️ No NVIDIA GPU detected, skipping CUDA installation"
            fi
        else
            echo "⚠️ Non-apt system detected. Please install dependencies manually:"
            echo "   - CMake 3.20+"
            echo "   - C++17 compatible compiler"
            echo "   - Boost, Eigen, Ceres Solver, CGAL, etc."
        fi
    elif [[ "$OS" == "macos" ]]; then
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo "🍺 Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        # Install dependencies with Homebrew
        brew update
        brew install \
            cmake \
            boost \
            eigen \
            gflags \
            glog \
            sqlite \
            freeimage \
            flann \
            cgal \
            ceres-solver \
            qt@5 \
            python
        
        # For Apple Silicon, ensure Metal frameworks are available
        if [[ "$IS_APPLE_SILICON" == true ]]; then
            echo "✅ Metal frameworks should be available on your Mac"
            echo "✅ CoreML frameworks should be available on your Mac"
        fi
    elif [[ "$OS" == "windows" ]]; then
        echo "🪟 On Windows, we recommend using vcpkg to install dependencies:"
        echo "   1. Install vcpkg: https://github.com/microsoft/vcpkg#quick-start-windows"
        echo "   2. vcpkg install boost:x64-windows eigen3:x64-windows ceres:x64-windows"
        echo "      freeimage:x64-windows flann:x64-windows cgal:x64-windows sqlite3:x64-windows"
        echo "   3. Set VCPKG_ROOT environment variable"
    fi
}

# Set up Python environment
setup_python() {
    echo "🐍 Setting up Python environment..."
    
    # Create and activate virtual environment
    if [[ "$OS" == "windows" ]]; then
        python -m venv "$PROJECT_ROOT/venv"
        echo "   To activate: $PROJECT_ROOT/venv/Scripts/activate"
    else
        python3 -m venv "$PROJECT_ROOT/venv"
        source "$PROJECT_ROOT/venv/bin/activate"
    fi
    
    # Install Python packages
    if [[ "$OS" == "windows" ]]; then
        echo "   Please activate the virtual environment and run:"
        echo "   pip install -r $PROJECT_ROOT/requirements.txt"
    else
        pip install --upgrade pip
        pip install torch torchvision numpy opencv-python matplotlib tqdm scipy
        
        # Install PyTorch with appropriate backend
        if [[ "$OS" == "macos" ]] && [[ "$IS_APPLE_SILICON" == true ]]; then
            # Install PyTorch for Apple Silicon
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cpu
            # Install MLX for Apple Silicon
            pip install mlx
        elif [[ "$OS" == "linux" ]] && command -v nvidia-smi &> /dev/null; then
            # Install PyTorch with CUDA support
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
        else
            # CPU only
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
        fi
    fi
}

# Download pre-trained models
download_models() {
    echo "📥 Downloading pre-trained models..."
    
    # Create models directory if it doesn't exist
    mkdir -p "$MODELS_DIR"
    
    # Run the download script
    python3 "$SCRIPT_DIR/download_models.py"
}

# Configure GPU support
configure_gpu() {
    echo "🖥️ Configuring GPU support..."
    
    if [[ "$OS" == "macos" ]] && [[ "$IS_APPLE_SILICON" == true ]]; then
        echo "   Configuring for Apple Silicon with Metal suppor