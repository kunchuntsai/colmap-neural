#!/bin/bash
set -e

# Default values
WORKSPACE_PATH=""
IMAGE_PATH=""
FEATURE_EXTRACTOR="superpoint"
MATCHER="superglue"
MVS_METHOD="mvsnet"
USE_GPU=true
BINARY="./build/colmap-neural-app/colmap-neural"
BENCHMARK=false
BENCHMARK_DATASET=""
BENCHMARK_OUTPUT="benchmark-results"

print_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --workspace=<path>           Path to workspace directory"
    echo "  --images=<path>              Path to input images"
    echo "  --feature-extractor=<type>   Feature extractor type (default: superpoint)"
    echo "                               Options: superpoint, netvlad, sift"
    echo "  --matcher=<type>             Feature matcher type (default: superglue)"
    echo "                               Options: superglue, nearest_neighbor"
    echo "  --mvs=<type>                 MVS method (default: mvsnet)"
    echo "                               Options: mvsnet, patch_match"
    echo "  --cpu                        Use CPU instead of GPU"
    echo "  --binary=<path>              Path to binary (default: $BINARY)"
    echo "  --benchmark                  Run benchmark instead of reconstruction"
    echo "  --benchmark-dataset=<path>   Dataset path for benchmarking"
    echo "  --benchmark-output=<path>    Output directory for benchmark results"
    echo "  --help                       Show this help message"
}

for arg in "$@"; do
    case $arg in
        --workspace=*)
            WORKSPACE_PATH="${arg#*=}"
            shift
            ;;
        --images=*)
            IMAGE_PATH="${arg#*=}"
            shift
            ;;
        --feature-extractor=*)
            FEATURE_EXTRACTOR="${arg#*=}"
            shift
            ;;
        --matcher=*)
            MATCHER="${arg#*=}"
            shift
            ;;
        --mvs=*)
            MVS_METHOD="${arg#*=}"
            shift
            ;;
        --cpu)
            USE_GPU=false
            shift
            ;;
        --binary=*)
            BINARY="${arg#*=}"
            shift
            ;;
        --benchmark)
            BENCHMARK=true
            shift
            ;;
        --benchmark-dataset=*)
            BENCHMARK_DATASET="${arg#*=}"
            shift
            ;;
        --benchmark-output=*)
            BENCHMARK_OUTPUT="${arg#*=}"
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

# Make sure the binary exists
if [ ! -f "$BINARY" ] && [ "$BENCHMARK" = false ]; then
    echo "Error: Binary not found at $BINARY"
    echo "Please build the project first with './scripts/build.sh'"
    exit 1
fi

# Check if running benchmark
if [ "$BENCHMARK" = true ]; then
    if [ -z "$BENCHMARK_DATASET" ]; then
        echo "Error: Benchmark dataset path is required for benchmarking."
        echo "Please specify with --benchmark-dataset=<path>"
        exit 1
    fi
    
    echo "Running benchmark..."
    mkdir -p "$BENCHMARK_OUTPUT"
    
    python3 scripts/benchmark.py \
        --dataset="$BENCHMARK_DATASET" \
        --output="$BENCHMARK_OUTPUT" \
        --feature_extractor="$FEATURE_EXTRACTOR" \
        --matcher="$MATCHER" \
        --mvs_method="$MVS_METHOD" \
        --use_gpu="$USE_GPU"
    
    echo "Benchmark complete! Results saved to $BENCHMARK_OUTPUT"
    exit 0
fi

# Check required arguments for reconstruction
if [ -z "$WORKSPACE_PATH" ]; then
    echo "Error: Workspace path is required."
    echo "Please specify with --workspace=<path>"
    exit 1
fi

if [ -z "$IMAGE_PATH" ]; then
    echo "Error: Image path is required."
    echo "Please specify with --images=<path>"
    exit 1
fi

# Create workspace directory if it doesn't exist
mkdir -p "$WORKSPACE_PATH"

# Run the reconstruction
echo "Running COLMAP Neural with:"
echo "  Workspace: $WORKSPACE_PATH"
echo "  Images: $IMAGE_PATH"
echo "  Feature Extractor: $FEATURE_EXTRACTOR"
echo "  Matcher: $MATCHER"
echo "  MVS Method: $MVS_METHOD"
echo "  GPU Enabled: $USE_GPU"

"$BINARY" \
    --workspace_path="$WORKSPACE_PATH" \
    --image_path="$IMAGE_PATH" \
    --feature_extractor="$FEATURE_EXTRACTOR" \
    --matcher="$MATCHER" \
    --mvs_method="$MVS_METHOD" \
    --use_gpu="$USE_GPU"

echo "Reconstruction complete! Results saved to $WORKSPACE_PATH"