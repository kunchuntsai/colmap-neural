# COLMAP Neural Enhancement

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Setup Guide](#setup-guide)
  - [1. Dependencies](#1-dependencies)
  - [2. Environment Setup](#2-environment-setup)
    - [2.1. Clone Repository](#21-clone-repository)
    - [2.2. Local Environment Setup](#22-local-environment-setup)
    - [2.3. Docker Environment Setup](#23-docker-environment-setup)
  - [3. Build Process](#3-build-process)
  - [4. Running the Application](#4-running-the-application)
- [Docker Development Workflow](#docker-development-workflow)
- [Features](#features)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Overview
This project enhances COLMAP with neural network capabilities for feature extraction, matching, and dense reconstruction while optimizing for Apple M4 Pro hardware. We use a plugin architecture that keeps COLMAP untouched while adding neural capabilities:
- **NetVLAD/SuperPoint** for neural feature extraction
- **SuperGlue** for learned feature matching
- **MVSNet** for enhanced MVS reconstruction
- Metal optimization for Apple M4 Pro

## Project Structure

```
colmap-neural/
├── colmap/                      # Unmodified COLMAP repository (submodule)
├── neural-extensions/           # Neural components as plugins
├── colmap-neural-app/           # Main application
├── models/                      # Pre-trained neural models
├── scripts/                     # Utility scripts
└── ...                          # Configuration files
```

## Setup Guide

### 1. Dependencies

This project requires several dependencies:

- **Core Libraries**:
  - COLMAP (v3.8+)
  - CMake (v3.20+)
  - C++ compiler with C++17 support
  - Boost, Eigen, Ceres Solver, OpenCV

- **Neural Network Support**:
  - PyTorch (2.0+)
  - Optional: TensorFlow, MLX (for Apple Silicon)

- **GPU Acceleration**:
  - CUDA 11.7+ (for NVIDIA GPUs)
  - Metal 3+ (for Apple Silicon)

### 2. Environment Setup

#### 2.1. Clone Repository

```bash
git clone --recurse-submodules https://github.com/your-username/colmap-neural.git
cd colmap-neural
```

#### 2.2. Local Environment Setup

For setting up on your local machine:

```bash
# Automated setup script for your OS (Linux, macOS, Windows)
./scripts/setup_local.sh
```

The script will:
- Install system dependencies based on your OS
- Set up Python environment with required packages
- Configure GPU support (CUDA or Metal)
- Download pre-trained models

#### 2.3. Docker Environment Setup

For containerized development:

```bash
# Set up Docker environment
./scripts/setup_docker.sh
```

This script will:
- Check for Docker and Docker Compose
- Create necessary configuration files
- Configure GPU support if available
- Set up volume mounts for data, models, and results

### 3. Build Process

Build the project with:

```bash
# For local build:
./scripts/build.sh

# For additional options:
./scripts/build.sh --help

# Available options:
#   --debug              Build in Debug mode
#   --release            Build in Release mode (default)
#   --clean              Clean build directory before building
#   --jobs=<num>         Number of parallel jobs
#   --with-cuda          Enable CUDA support
#   --with-metal         Enable Metal support (macOS only)
#   --build-colmap       Build COLMAP from source (default)
#   --use-system-colmap  Use system-installed COLMAP
```

### 4. Running the Application

Run the application with:

```bash
./scripts/run.sh --workspace=/path/to/workspace --images=/path/to/images

# For all available options:
./scripts/run.sh --help

# Available options:
#   --workspace=<path>           Path to workspace directory
#   --images=<path>              Path to input images
#   --feature-extractor=<type>   Feature extractor type (default: superpoint)
#                                Options: superpoint, netvlad, sift
#   --matcher=<type>             Feature matcher type (default: superglue)
#                                Options: superglue, nearest_neighbor
#   --mvs=<type>                 MVS method (default: mvsnet)
#                                Options: mvsnet, patch_match
#   --cpu                        Use CPU instead of GPU
#   --benchmark                  Run benchmark instead of reconstruction
#   --benchmark-dataset=<path>   Dataset path for benchmarking
```

## Docker Development Workflow

Our Docker setup provides a full development environment:

```bash
# 1. Set up Docker environment
./scripts/setup_docker.sh

# 2. Start and enter container
docker-compose up -d
docker-compose exec neural-colmap bash

# 3. Inside container, build and run
./scripts/build.sh
./scripts/run.sh --help
```

This approach separates the environment setup from the build process, giving you more flexibility during development.

## Features

- **Neural Feature Extraction**: Replace SIFT with neural network-based feature detectors
- **Advanced Feature Matching**: Replace nearest-neighbor matching with learnable matching
- **Enhanced Dense Reconstruction**: Implement learning-based MVS approaches
- **Metal Optimization**: Optimized for performance on Apple M4 Pro

## Documentation

For detailed documentation, see:
- [Environment Setup](doc/environment.md)
- [Plugin Architecture](doc/neural_architecture.md)
- [M4 Pro Optimizations](doc/m4_optimizations.md)

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.