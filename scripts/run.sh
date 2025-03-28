#!/bin/bash
# scripts/run.sh

set -e

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
APP_PATH="$BUILD_DIR/colmap-neural-app/colmap-neural"

# Default options
WORKSPACE=""
IMAGES=""
FEATURE_EXTRACTOR="superpoint"
MATCHER="superglue"
MVS="mvsnet"
USE_CPU=false
BENCHMARK=false
BENCHMARK_DATASET=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --workspace=*)
            WORKSPACE="${key#*=}"
            shift
            ;;
        --images=*)
            IMAGES="${key#*=}"
            shift
            ;;
        --feature-extractor=*)
            FEATURE_EXTRACTOR="${key#*=}"
            shift
            ;;
        --matcher=*)
            MATCHER="${key#*=}"
            shift
            ;;
        --mvs=*)
            MVS="${key#*=}"
            shift
            ;;
        --cpu)
            USE_CPU=true
            shift
            ;;
        --benchmark)
            BENCHMARK=true
            shift
            ;;
        --benchmark-dataset=*)
            BENCHMARK_DATASET="${key#*=}"
            shift
            ;;
        --help)
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
            echo "  --benchmark                  Run benchmark instead of reconstruction"
            echo "  --benchmark-dataset=<path>   Dataset path for benchmarking"
            exit 0
            ;;
        *)
            echo "Unknown option: $key"
            exit 1
            ;;
    esac
done

# Check if the application exists
if [ ! -f "$APP_PATH" ]; then
    echo "❌ Application not found at $APP_PATH"
    echo "   Please build the project first using ./scripts/build.sh"
    exit 1
fi

# Add command line arguments based on options
CMD_ARGS=()

# Handle workspace directory
if [ -n "$WORKSPACE" ]; then
    CMD_ARGS+=(--project_path="$WORKSPACE")
else
    echo "❌ No workspace specified!"
    echo "   Please specify a workspace directory with --workspace=/path/to/workspace"
    exit 1
fi

# Handle input images
if [ -n "$IMAGES" ]; then
    if [ ! -d "$IMAGES" ]; then
        echo "❌ Images directory does not exist: $IMAGES"
        exit 1
    fi
    CMD_ARGS+=(--image_path="$IMAGES")
else
    echo "❌ No images directory specified!"
    echo "   Please specify an images directory with --images=/path/to/images"
    exit 1
fi

# Neural components configuration
if [ "$FEATURE_EXTRACTOR" = "superpoint" ] || [ "$FEATURE_EXTRACTOR" = "netvlad" ]; then
    CMD_ARGS+=(--use_neural=true)
    CMD_ARGS+=(--feature_extractor="$FEATURE_EXTRACTOR")
elif [ "$FEATURE_EXTRACTOR" = "sift" ]; then
    CMD_ARGS+=(--use_neural=false)
fi

if [ "$MATCHER" = "superglue" ]; then
    CMD_ARGS+=(--use_neural=true)
    CMD_ARGS+=(--matcher="$MATCHER")
fi

if [ "$MVS" = "mvsnet" ]; then
    CMD_ARGS+=(--use_neural=true)
    CMD_ARGS+=(--mvs="$MVS")
fi

# GPU/CPU configuration
if [ "$USE_CPU" = true ]; then
    CMD_ARGS+=(--use_gpu=false)
else
    CMD_ARGS+=(--use_gpu=true)
fi

# Benchmark mode
if [ "$BENCHMARK" = true ]; then
    CMD_ARGS+=(--benchmark=true)
    
    if [ -n "$BENCHMARK_DATASET" ]; then
        if [ ! -d "$BENCHMARK_DATASET" ]; then
            echo "❌ Benchmark dataset directory does not exist: $BENCHMARK_DATASET"
            exit 1
        fi
        CMD_ARGS+=(--benchmark_dataset="$BENCHMARK_DATASET")
    else
        echo "❌ No benchmark dataset specified!"
        echo "   Please specify a benchmark dataset with --benchmark-dataset=/path/to/dataset"
        exit 1
    fi
fi

# Run the application
echo "🚀 Running COLMAP Neural..."
"$APP_PATH" "${CMD_ARGS[@]}"