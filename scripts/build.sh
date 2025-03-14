#!/bin/bash
set -e

# Parse command line arguments
CMAKE_OPTIONS=""
BUILD_TYPE="Release"
CLEAN_BUILD=false
NUM_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

print_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --debug              Build in Debug mode"
    echo "  --release            Build in Release mode (default)"
    echo "  --clean              Clean build directory before building"
    echo "  --jobs=<num>         Number of parallel jobs (default: $NUM_JOBS)"
    echo "  --with-cuda          Enable CUDA support"
    echo "  --with-metal         Enable Metal support (macOS only)"
    echo "  --build-colmap       Build COLMAP from source (default)"
    echo "  --use-system-colmap  Use system-installed COLMAP"
    echo "  --help               Show this help message"
}

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
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --jobs=*)
            NUM_JOBS="${arg#*=}"
            shift
            ;;
        --with-cuda)
            CMAKE_OPTIONS="$CMAKE_OPTIONS -DCOLMAP_NEURAL_CUDA_ENABLE=ON"
            shift
            ;;
        --with-metal)
            CMAKE_OPTIONS="$CMAKE_OPTIONS -DCOLMAP_NEURAL_METAL_ENABLE=ON"
            shift
            ;;
        --build-colmap)
            CMAKE_OPTIONS="$CMAKE_OPTIONS -DCOLMAP_NEURAL_BUILD_COLMAP=ON"
            shift
            ;;
        --use-system-colmap)
            CMAKE_OPTIONS="$CMAKE_OPTIONS -DCOLMAP_NEURAL_BUILD_COLMAP=OFF"
            shift
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            # Unknown option
            echo "Unknown option: $arg"
            print_usage
            exit 1
            ;;
    esac
done

# Set build directory
BUILD_DIR="build"

# Clean build directory if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
echo "Configuring with CMake (Build type: $BUILD_TYPE)..."
cmake .. \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    $CMAKE_OPTIONS

# Build
echo "Building with $NUM_JOBS parallel jobs..."
cmake --build . --parallel "$NUM_JOBS"

echo "Build complete! Binaries are located in $BUILD_DIR/colmap-neural-app/"