#!/bin/bash
# scripts/setup_docker.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🐳 Setting up Docker environment for COLMAP Neural Enhancement"
echo "=============================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first:"
    echo "   https://docs.docker.com/get-docker/"
    exit 1
fi

# Check for NVIDIA Docker support if NVIDIA GPU is present
if command -v nvidia-smi &> /dev/null; then
    if ! command -v nvidia-docker &> /dev/null && ! docker info | grep -q "Runtimes:.*nvidia"; then
        echo "⚠️ NVIDIA GPU detected, but NVIDIA Docker support is not installed."
        echo "   For GPU acceleration, install NVIDIA Container Toolkit:"
        echo "   https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
    else
        echo "✅ NVIDIA Docker support detected."
        USE_NVIDIA=true
    fi
fi

# Build the Docker image
echo "🏗️  Building Docker image..."
if [ "$USE_NVIDIA" = true ]; then
    # Build with CUDA support
    docker build -t colmap-neural:cuda -f "$PROJECT_ROOT/docker/Dockerfile" \
        --build-arg WITH_CUDA=ON \
        --build-arg WITH_METAL=OFF \
        "$PROJECT_ROOT"
else
    # Build CPU-only version
    docker build -t colmap-neural:cpu -f "$PROJECT_ROOT/docker/Dockerfile" \
        --build-arg WITH_CUDA=OFF \
        --build-arg WITH_METAL=OFF \
        "$PROJECT_ROOT"
fi

echo "✅ Docker setup completed!"
echo ""
echo "🚀 To run the application in Docker:"
if [ "$USE_NVIDIA" = true ]; then
    echo "   docker run --gpus all -v /path/to/data:/data colmap-neural:cuda [options]"
else
    echo "   docker run -v /path/to/data:/data colmap-neural:cpu [options]"
fi