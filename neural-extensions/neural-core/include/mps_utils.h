// neural-extensions/neural-core/include/mps_utils.h
#pragma once

#ifdef __APPLE__

#include <string>

namespace neural {
namespace metal {

// Initialize Metal compute capabilities
bool InitializeMetalCompute();

// Check if Metal Performance Shaders (MPS) are available
bool IsMPSAvailable();

// Get information about the Metal device
std::string GetMetalDeviceInfo();

// Optimize model for specific Metal device if needed
bool OptimizeForDevice(const std::string& model_path);

} // namespace metal
} // namespace neural

#endif // __APPLE__