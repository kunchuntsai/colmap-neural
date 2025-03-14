# COLMAP Neural Enhancement - Development

This project enhances COLMAP with neural network capabilities for feature extraction, matching, and dense reconstruction while optimizing for Apple M4 Pro hardware.

## Project Structure

```
colmap-neural/
├── colmap/                      # Unmodified COLMAP repository
├── neural-extensions/           # Our neural components as plugins
│   ├── feature/                 # Feature extraction extensions
│   │   ├── superpoint/
│   │   │   ├── include/
│   │   │   │   └── superpoint.h
│   │   │   ├── src/
│   │   │   │   └── superpoint.cc
│   │   │   └── CMakeLists.txt
│   │   └── netvlad/
│   │       ├── include/
│   │       │   └── netvlad.h
│   │       ├── src/
│   │       │   └── netvlad.cc
│   │       └── CMakeLists.txt
│   ├── matcher/                 # Matching extensions
│   │   └── superglue/
│   │       ├── include/
│   │       │   └── superglue.h
│   │       ├── src/
│   │       │   └── superglue.cc
│   │       └── CMakeLists.txt
│   ├── mvs/                     # MVS extensions
│   │   └── mvsnet/
│   │       ├── include/
│   │       │   └── mvsnet.h
│   │       ├── src/
│   │       │   └── mvsnet.cc
│   │       └── CMakeLists.txt
│   ├── neural-core/             # Common neural utilities
│   │   ├── include/
│   │   │   ├── model_loader.h
│   │   │   ├── mps_utils.h
│   │   │   ├── inference.h
│   │   │   └── registry.h
│   │   ├── src/
│   │   │   ├── model_loader.cc
│   │   │   ├── mps_utils.cc
│   │   │   ├── inference.cc
│   │   │   └── registry.cc
│   │   └── CMakeLists.txt
│   └── CMakeLists.txt           # Main CMake file for all extensions
├── colmap-neural-app/           # Our application that uses both COLMAP and extensions
│   ├── include/
│   ├── src/
│   │   └── main.cc
│   └── CMakeLists.txt
├── cmake/                       # CMake modules for finding dependencies
│   ├── FindMetal.cmake
│   ├── FindTorch.cmake
│   └── FindCOLMAP.cmake
├── models/                      # Pre-trained neural models
│   ├── superpoint/
│   ├── superglue/
│   ├── netvlad/
│   └── mvsnet/
├── scripts/                     # Utility scripts
│   ├── benchmark.py             # Performance benchmarking
│   ├── download_models.py       # Script to download pre-trained models
│   └── convert_to_coreml.py     # CoreML conversion utility
├── CMakeLists.txt               # Top-level CMake that builds everything
├── Dockerfile                   # Docker configuration
├── docker-compose.yml           # Docker compose configuration
└── .dockerignore                # Docker ignore file
```

## Extension Points

COLMAP provides several well-defined extension points we can leverage:

### 1. Feature Extraction

```cpp
// In neural-extensions/feature/superpoint/include/superpoint.h
#include <colmap/feature/types.h>
#include <colmap/feature/extraction.h>

namespace colmap_neural {

class SuperPointFeatureExtractor : public colmap::FeatureExtractor {
 public:
  SuperPointFeatureExtractor();
  
  bool Extract(const colmap::Bitmap& bitmap, 
               colmap::FeatureKeypoints* keypoints,
               colmap::FeatureDescriptors* descriptors) override;
 
 private:
  // Neural network implementation
};

// Register with the plugin system
REGISTER_FEATURE_EXTRACTOR(superpoint, SuperPointFeatureExtractor);

} // namespace colmap_neural
```

### 2. Feature Matching

```cpp
// In neural-extensions/matcher/superglue/include/superglue.h
#include <colmap/feature/matcher.h>

namespace colmap_neural {

class SuperGlueMatcher : public colmap::FeatureMatcher {
 public:
  SuperGlueMatcher();
  
  bool Match(const colmap::FeatureDescriptors& descriptors1,
             const colmap::FeatureDescriptors& descriptors2,
             colmap::TwoViewGeometry* two_view_geometry) override;
 
 private:
  // Neural network implementation
};

// Register with the plugin system
REGISTER_FEATURE_MATCHER(superglue, SuperGlueMatcher);

} // namespace colmap_neural
```

### 3. Neural Utilities

Our Neural Core module provides common functionality:

- **Model Loading**: Unified model loading from various formats
- **Metal Integration**: Metal Performance Shaders (MPS) utilities for Apple Silicon
- **Registry System**: Plugin registration and discovery system
- **Inference**: Common neural network inference utilities

## Apple M4 Pro Optimizations

Our neural extensions are optimized for Apple M4 Pro:

1. **PyTorch MPS Backend**: 
   - Uses Metal Performance Shaders for GPU acceleration
   - Implemented in `neural-core/mps_utils.h`

2. **Fallback Mechanisms**:
   - Graceful fallback to CPU when needed
   - Performance monitoring for optimal device selection

3. **Metal-Specific Optimizations**:
   - Direct Metal compute shaders for critical operations
   - Memory management optimized for unified memory architecture

4. **CoreML Integration**:
   - Optional conversion to CoreML for deployment
   - Using `convert_to_coreml.py` utility

## Performance Benchmarks

Run our benchmarking script to compare against standard COLMAP:

```bash
python scripts/benchmark.py --dataset=your_dataset --output=benchmark-results
```

The script will generate:
- Feature extraction time comparison
- Matching accuracy and speed metrics
- Reconstruction quality metrics
- Memory usage statistics

## Contribution Guidelines

1. Create a new branch for each feature
2. Maintain tests for each extension
3. Follow COLMAP's code style
4. Update documentation with changes

This plugin architecture ensures our neural enhancements remain compatible with future COLMAP updates while maintaining a clean and maintainable codebase.