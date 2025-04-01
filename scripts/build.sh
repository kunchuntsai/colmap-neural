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
WITH_METAL="OFF"
WITH_DOCKER="OFF"

# Detect platform
if [[ "$(uname)" == "Darwin" ]]; then
    WITH_METAL="ON"
    echo "🍎 Detected macOS platform, enabling Metal"
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

echo "🏗️  Building COLMAP Neural Phase 1 with configuration:"
echo "  📁 Build directory: $BUILD_DIR"
echo "  🛠️  Build type: $BUILD_TYPE"
echo "  🍎 Metal support: $WITH_METAL"
echo "  🐳 Docker environment: $WITH_DOCKER"

# Change to build directory
cd "$BUILD_DIR"

# Check if COLMAP source code is available
COLMAP_SOURCE_DIR="$COLMAP_NEURAL_ROOT/external/colmap"
if [ ! -d "$COLMAP_SOURCE_DIR" ]; then
    echo "⚠️  COLMAP source code not found at $COLMAP_SOURCE_DIR"
    
    # Create directory if it doesn't exist
    mkdir -p "$COLMAP_NEURAL_ROOT/external"
    
    echo "🔍 Cloning COLMAP repository..."
    git clone https://github.com/colmap/colmap.git "$COLMAP_SOURCE_DIR"
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to clone COLMAP repository"
        exit 1
    fi
    
    # Switch to a stable version tag
    cd "$COLMAP_SOURCE_DIR"
    git checkout 3.8
    cd "$BUILD_DIR"
    
    echo "✅ COLMAP repository cloned successfully"
else
    echo "✅ Using existing COLMAP source code at $COLMAP_SOURCE_DIR"
fi

# Configure with CMake
echo "⚙️  Configuring with CMake..."
cmake "$COLMAP_NEURAL_ROOT" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DWITH_METAL="$WITH_METAL" \
    -DWITH_DOCKER="$WITH_DOCKER" \
    -DBUILD_COLMAP=ON

# Build COLMAP first
echo "🔨 Building COLMAP (Step 1/2)..."
cmake --build . --target colmap_ext -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

if [ $? -ne 0 ]; then
    echo "❌ Failed to build COLMAP"
    exit 1
fi

echo "✅ COLMAP built successfully"

# Now build the app
echo "🔨 Building colmap-neural-app (Step 2/2)..."
cmake --build . --target colmap-neural -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

if [ $? -ne 0 ]; then
    echo "❌ Failed to build colmap-neural-app"
    exit 1
fi

echo "✅ colmap-neural-app built successfully"

# Success message
echo "✅ Build completed successfully!"
echo "🚀 You can run the application with ./bin/colmap-neural"