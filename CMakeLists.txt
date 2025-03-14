cmake_minimum_required(VERSION 3.10)
project(COLMAP_Neural VERSION 1.0)

# Add CMake modules path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Find dependencies
find_package(Torch REQUIRED)
if(APPLE)
  find_package(Metal)
endif()

# Add COLMAP as a subproject (but don't modify it)
option(COLMAP_NEURAL_BUILD_COLMAP "Build COLMAP from source" ON)
if(COLMAP_NEURAL_BUILD_COLMAP)
  add_subdirectory(colmap)
else()
  find_package(COLMAP REQUIRED)
endif()

# Add our neural extensions
add_subdirectory(neural-extensions)

# Add our main application 
add_subdirectory(colmap-neural-app)
