#!/bin/bash
set -e

echo "Setting up Docker environment for COLMAP Neural..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker first:"
    echo "https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Please install Docker Compose first:"
    echo "https://docs.docker.com/compose/install/"
    exit 1
fi

# Check for NVIDIA GPU and Docker support
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected."
    
    # Check for NVIDIA Container Toolkit
    if ! docker info | grep -q "Runtimes.*nvidia"; then
        echo "NVIDIA Container Toolkit not found. Please install it for GPU support:"
        echo "https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
        exit 1
    fi
    
    echo "NVIDIA Container Toolkit detected. GPU support will be enabled."
else
    echo "No NVIDIA GPU detected. Proceeding with CPU-only Docker configuration."
fi

# Check for submodules and initialize/update them if needed
if [ ! -d "colmap" ]; then
    echo "Initializing and updating submodules..."
    git submodule update --init --recursive
else
    echo "Submodules already present."
fi

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    echo "Error: Dockerfile not found. Make sure you're in the project root directory."
    exit 1
fi

# Create data and benchmark-results directories if they don't exist
mkdir -p data
mkdir -p models
mkdir -p benchmark-results

echo "Docker environment setup complete!"
echo ""
echo "Building and starting the Docker container..."

# Build the Docker image
docker-compose build

# Start the container in detached mode
docker-compose up -d

echo ""
echo "Docker container has been built and started!"
echo "To enter the container, run:"
echo "  docker-compose exec neural-colmap bash"
echo ""
echo "For development, these directories are mounted into the container:"
echo "  ./data                          # For input images and datasets"
echo "  ./models                        # For pre-trained neural models"
echo "  ./benchmark-results             # For benchmark output"