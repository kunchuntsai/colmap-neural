# CMakeLists.txt
cmake_minimum_required(VERSION 3.20)
project(colmap-neural VERSION 0.1.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set CMake policies
if(POLICY CMP0144)
  cmake_policy(SET CMP0144 NEW)
endif()

# Add CMake modules directory
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Options
option(WITH_CUDA "Build with CUDA support" OFF)
option(WITH_METAL "Build with Metal support" ON)  # Default ON for Apple Silicon
option(WITH_DOCKER "Building in Docker environment" OFF)
option(BUILD_COLMAP "Build COLMAP from source" ON)  # New option to build COLMAP

# Force disable CUDA as specified
set(WITH_CUDA OFF)

# Check platform-specific features
if(APPLE)
    set(WITH_METAL ON)
    message(STATUS "Building for Apple platform with Metal support")
    
    # Check for Apple Silicon (M4 Pro)
    execute_process(
        COMMAND sysctl -n machdep.cpu.brand_string
        OUTPUT_VARIABLE CPU_BRAND
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(CPU_BRAND MATCHES "Apple")
        message(STATUS "Detected Apple Silicon: ${CPU_BRAND}")
        add_definitions(-DAPPLE_SILICON)
        
        # Enable Apple M4-specific optimizations
        add_compile_options(-mcpu=apple-m4)
        
        # Add Metal Performance Shaders support
        find_library(METAL_PERFORMANCE_SHADERS MetalPerformanceShaders)
        if(METAL_PERFORMANCE_SHADERS)
            message(STATUS "Found Metal Performance Shaders")
            add_definitions(-DWITH_MPS)
        endif()
    endif()
endif()

# COLMAP dependency - either find installed or build from source
if(BUILD_COLMAP)
    # Build COLMAP from source
    include(ExternalProject)
    set(COLMAP_INSTALL_DIR ${CMAKE_BINARY_DIR}/colmap-install)
    set(COLMAP_SOURCE_DIR ${CMAKE_SOURCE_DIR}/external/colmap)
    
    # Create external directory if it doesn't exist
    if(NOT EXISTS ${COLMAP_SOURCE_DIR})
        file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/external)
    endif()
    
    # Configure COLMAP build options
    set(COLMAP_CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${COLMAP_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DTESTS_ENABLED=OFF
        -DGUI_ENABLED=ON
        -DCUDA_ENABLED=OFF
        -DOPENMP_ENABLED=ON
    )
    
    # Add Apple M4 Pro specific optimizations
    if(APPLE AND WITH_METAL)
        list(APPEND COLMAP_CMAKE_ARGS -DCMAKE_CXX_FLAGS="-O3 -mcpu=apple-m4")
        list(APPEND COLMAP_CMAKE_ARGS -DSIMD_ENABLED=ON)
        
        # Pass Metal flags to COLMAP if it supports them
        list(APPEND COLMAP_CMAKE_ARGS -DWITH_METAL=ON)
    endif()
    
    # Add external project
    ExternalProject_Add(colmap_ext
        SOURCE_DIR ${COLMAP_SOURCE_DIR}
        CMAKE_ARGS ${COLMAP_CMAKE_ARGS}
        INSTALL_DIR ${COLMAP_INSTALL_DIR}
        PREFIX ${CMAKE_BINARY_DIR}/colmap_ext-prefix
    )
    
    # Set COLMAP include and library paths
    set(COLMAP_INCLUDE_DIRS
        ${COLMAP_INSTALL_DIR}/include
        ${COLMAP_SOURCE_DIR}/src
    )
    
    # Set library paths based on platform
    if(WIN32)
        set(COLMAP_LIBRARIES ${COLMAP_INSTALL_DIR}/lib/colmap.lib)
    elseif(APPLE)
        set(COLMAP_LIBRARIES ${COLMAP_INSTALL_DIR}/lib/libcolmap.dylib)
    else()
        set(COLMAP_LIBRARIES ${COLMAP_INSTALL_DIR}/lib/libcolmap.so)
    endif()
    
    # Create imported target
    add_library(COLMAP::COLMAP UNKNOWN IMPORTED)
    set_target_properties(COLMAP::COLMAP PROPERTIES
        IMPORTED_LOCATION ${COLMAP_LIBRARIES}
        INTERFACE_INCLUDE_DIRECTORIES "${COLMAP_INCLUDE_DIRS}"
    )
    add_dependencies(COLMAP::COLMAP colmap_ext)
    
else()
    # Find pre-installed COLMAP
    find_package(COLMAP REQUIRED)
endif()

# Find other dependencies
find_package(Boost REQUIRED COMPONENTS program_options filesystem system)
find_package(Eigen3 REQUIRED)
find_package(OpenCV REQUIRED)
find_package(Torch REQUIRED)
find_package(glog REQUIRED)
find_package(gflags REQUIRED)

# Metal support for Apple platforms (particularly M4 Pro)
if(APPLE AND WITH_METAL)
    find_package(Metal)
    if(Metal_FOUND)
        add_definitions(-DWITH_METAL)
        message(STATUS "Building with Metal support")
        
        # Find additional Apple frameworks for ML acceleration
        find_library(ACCELERATE_FRAMEWORK Accelerate)
        find_library(CORE_ML CoreML)
        
        if(ACCELERATE_FRAMEWORK)
            message(STATUS "Found Accelerate Framework")
            add_definitions(-DWITH_ACCELERATE)
        endif()
        
        if(CORE_ML)
            message(STATUS "Found CoreML Framework")
            add_definitions(-DWITH_CORE_ML)
        endif()
    else()
        message(WARNING "Metal requested but not found")
    endif()
endif()

# CUDA is explicitly disabled for Apple M4 Pro
# CUDA section kept for reference but will not be used
if(WITH_CUDA)
    message(STATUS "CUDA support is disabled for Apple M4 Pro builds")
    set(WITH_CUDA OFF)
endif()

# Add subdirectories
add_subdirectory(neural-extensions)
add_subdirectory(colmap-neural-app)

# Install targets
install(TARGETS colmap-neural
        RUNTIME DESTINATION bin)

# Print configuration summary
message(STATUS "Configuration Summary:")
message(STATUS "  COLMAP Neural Version: ${PROJECT_VERSION}")
message(STATUS "  C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  CUDA Support: ${WITH_CUDA}")
message(STATUS "  Metal Support: ${WITH_METAL}")
message(STATUS "  Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Build COLMAP from source: ${BUILD_COLMAP}")
if(BUILD_COLMAP)
    message(STATUS "  COLMAP install location: ${COLMAP_INSTALL_DIR}")
endif()