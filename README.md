# COLMAP Neural Enhancement

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Setup Guide](#setup-guide)
  - [1. Dependencies](#1-dependencies)
  - [2. Environment Setup](#2-environment-setup)
    - [2.1. Clone Repository](#21-clone-repository)
    - [2.2. Local Environment Setup](#22-local-environment-setup)
    - [2.3. Nix Environment Setup](#23-nix-environment-setup)
  - [3. Build Process](#3-build-process)
  - [4. Running the Application](#4-running-the-application)
- [Nix Development Workflow](#nix-development-workflow)
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
├── external/colmap/             # Unmodified COLMAP repository (submodule)
├── neural-extensions/           # Neural components as plugins
├── colmap-neural-app/           # Main application
├── scripts/                     # Utility scripts
├── flake.nix                    # Nix flake configuration
├── shell.nix                    # Compatibility wrapper for flake.nix
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
git submodule update --init --recursive
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

#### 2.3. Nix Environment Setup

For a reproducible development environment with Nix, we recommend using our flake-based setup:

```bash
# Make sure you have flakes enabled in your Nix configuration
# Edit ~/.config/nix/nix.conf or /etc/nix/nix.conf and add:
# experimental-features = nix-command flakes

# Enter the development environment with flakes (recommended)
nix develop

# If you don't have flakes enabled, you can use the compatibility wrapper:
nix-shell
```

This will:
- Set up a reproducible environment with all required dependencies
- Configure GPU support based on your hardware (CUDA or Metal)
- Ensure consistent library versions across development machines

### 2.4. Docker Environment Setup

For containerized development with Docker:

```bash
# Build and configure Docker environment
./scripts/setup_docker.sh

# Run in Docker container
docker run -v /path/to/data:/data colmap-neural:cuda [options]
```

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

## Nix Development Workflow

Our Nix setup provides a fully reproducible development environment using flakes:

```bash
# 1. Standard development environment (auto-detects platform)
nix develop

# 2. Debug development environment (includes gdb and valgrind)
nix develop .#debug

# 3. Force specific GPU backend
nix develop .#cuda   # NVIDIA GPU support
nix develop .#metal  # Apple Metal support

# 4. Build packages directly
nix build .#colmap   # Build standard COLMAP
nix build            # Build neural-enhanced COLMAP

# 5. Run the application directly 
nix run              # Run the neural-enhanced COLMAP
```

For those without flakes enabled, the `shell.nix` provides a compatibility layer:

```bash
# Enter standard development environment
nix-shell
```

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
- [Nix Flake Setup](doc/nix_setup.md)

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.