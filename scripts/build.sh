#!/bin/bash
# scripts/build.sh

set -e

# Get the project root directory
if [ -z "$COLMAP_NEURAL_ROOT" ]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    COLMAP_NEURAL_ROOT="$(dirname "$SCRIPT_DIR")"
fi

# Parse arguments
BUILD_TYPE="Release"
BUILD_DIR="$COLMAP_NEURAL_ROOT/build"
WITH_CUDA="OFF"
WITH_METAL="OFF"
WITH_DOCKER="OFF"

# Detect platform
if [[ "$(uname)" == "Darwin" ]]; then
    WITH_METAL="ON"
    echo "🍎 Detected macOS platform, enabling Metal"
else
    WITH_CUDA="ON"
    echo "🐧 Detected non-macOS platform, enabling CUDA"
fi

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --cuda)
            WITH_CUDA="ON"
            shift
            ;;
        --no-cuda)
            WITH_CUDA="OFF"
            shift
            ;;
        --metal)
            WITH_METAL="ON"
            shift
            ;;
        --no-metal)
            WITH_METAL="OFF"
            shift
            ;;
        --docker)
            WITH_DOCKER="ON"
            shift
            ;;
        --clean)
            echo "🧹 Cleaning build directory..."
            rm -rf "$BUILD_DIR"
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --debug          Build in debug mode"
            echo "  --release        Build in release mode (default)"
            echo "  --cuda           Enable CUDA support"
            echo "  --no-cuda        Disable CUDA support"
            echo "  --metal          Enable Metal support"
            echo "  --no-metal       Disable Metal support"
            echo "  --docker         Building in Docker environment"
            echo "  --clean          Clean build directory before build"
            exit 0
            ;;
    esac
done

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

echo "🏗️  Building COLMAP Neural with configuration:"
echo "  📁 Build directory: $BUILD_DIR"
echo "  🛠️  Build type: $BUILD_TYPE"
echo "  🖥️  CUDA support: $WITH_CUDA"
echo "  🍎 Metal support: $WITH_METAL"
echo "  🐳 Docker environment: $WITH_DOCKER"

# Change to build directory
cd "$BUILD_DIR"

# Configure with CMake
echo "⚙️  Configuring with CMake..."
cmake "$COLMAP_NEURAL_ROOT" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DWITH_CUDA="$WITH_CUDA" \
    -DWITH_METAL="$WITH_METAL" \
    -DWITH_DOCKER="$WITH_DOCKER"

# Build
echo "🔨 Building..."
cmake --build . -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

# Success message
echo "✅ Build completed successfully!"
echo "🚀 You can run the application with ./colmap-neural-app/colmap-neural"