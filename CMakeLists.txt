# Top-level CMakeLists.txt
# Detect if we're in a Nix build environment
if(DEFINED ENV{NIX_BUILD_TOP})
    message(STATUS "Building in Nix environment")
    # Don't include user configuration in Nix build
else()
    message(STATUS "Building in local environment")
    # Include user configuration if it exists (for local builds)
    include(CMakeLists.txt.user OPTIONAL)
endif()

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
option(BUILD_COLMAP "Build COLMAP from source" ON)

# Force disable CUDA as specified
set(WITH_CUDA OFF)

# Check platform-specific features
if(APPLE)
    set(WITH_METAL ON)
    message(STATUS "Building for Apple platform with Metal support")
    
    # Check for Apple Silicon
    execute_process(
        COMMAND sysctl -n machdep.cpu.brand_string
        OUTPUT_VARIABLE CPU_BRAND
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(CPU_BRAND MATCHES "Apple")
        message(STATUS "Detected Apple Silicon: ${CPU_BRAND}")
        add_definitions(-DAPPLE_SILICON)
        
        # Enable Apple-specific optimizations
        add_compile_options(-O3)
        
        # Find Metal and related frameworks
        find_package(Metal REQUIRED)
        if(METAL_FOUND)
            message(STATUS "Found Metal frameworks")
            add_definitions(-DWITH_METAL)
        endif()
    endif()
endif()

# COLMAP dependency - either find installed or build from source
if(BUILD_COLMAP)
    # First include our COLMAP patching script and define COLMAP paths
    include(${CMAKE_SOURCE_DIR}/cmake/PatchCOLMAP.cmake)
    set(COLMAP_INSTALL_DIR ${CMAKE_BINARY_DIR}/colmap-install)
    set(COLMAP_SOURCE_DIR ${CMAKE_SOURCE_DIR}/external/colmap)
    
    # Apply patches to COLMAP source code if needed
    patch_colmap_files(${COLMAP_SOURCE_DIR})
    
    # Build COLMAP from source
    include(ExternalProject)
    
    # Configure COLMAP build options
    set(COLMAP_CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${COLMAP_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DTESTS_ENABLED=OFF
        -DGUI_ENABLED=ON
        -DCUDA_ENABLED=OFF
        -DOPENMP_ENABLED=ON
        -DCMAKE_POLICY_DEFAULT_CMP0075=NEW
        -DCMAKE_POLICY_DEFAULT_CMP0074=NEW
        -DCMAKE_MACOSX_RPATH=ON
    )
    
    # Add Apple Silicon specific optimizations
    if(APPLE AND WITH_METAL)
        # Add optimization flags separately to avoid parsing issues
        list(APPEND COLMAP_CMAKE_ARGS -DCMAKE_CXX_FLAGS="-O3")
        list(APPEND COLMAP_CMAKE_ARGS -DCMAKE_CXX_FLAGS_RELEASE="-O3")
        
        # Check if we can detect Apple Silicon before adding specific flags
        if(CPU_BRAND MATCHES "Apple")
            # Add Apple-specific flags as separate options
            list(APPEND COLMAP_CMAKE_ARGS -DAPPLE_SILICON=ON)
        endif()
        
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
    
    # Configure interface library for COLMAP after build
    # Generate the ConfigureCOLMAP.cmake file from the template
    configure_file(
        ${CMAKE_SOURCE_DIR}/cmake/ConfigureCOLMAP.cmake.in
        ${CMAKE_BINARY_DIR}/cmake/ConfigureCOLMAP.cmake
        @ONLY
    )
    
    # Create an interface target for COLMAP that can be used by our app
    add_library(colmap_interface INTERFACE)
    add_dependencies(colmap_interface colmap_ext)
    
    # Set include directories for the interface
    target_include_directories(colmap_interface INTERFACE 
        ${COLMAP_SOURCE_DIR}/src
        ${COLMAP_INSTALL_DIR}/include
    )
    
    # Add an alias so we can use the same target name as when finding installed COLMAP
    add_library(COLMAP::COLMAP ALIAS colmap_interface)
    
else()
    # Find pre-installed COLMAP
    find_package(COLMAP REQUIRED)
endif()

# Find common dependencies
find_package(Boost REQUIRED COMPONENTS program_options filesystem system)
find_package(Eigen3 REQUIRED)
find_package(OpenCV REQUIRED)
find_package(glog REQUIRED)
find_package(gflags REQUIRED)
find_package(ONNXRuntime REQUIRED)

# Add the neural-extensions directory
add_subdirectory(neural-extensions)

# Find all source and header files in the src directory
file(GLOB_RECURSE SRC_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.h")
file(GLOB_RECURSE SRC_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc")

# Add the main executable
add_executable(colmap-neural ${SRC_SOURCES} ${SRC_HEADERS})

# Set include directories
target_include_directories(colmap-neural PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${COLMAP_INCLUDE_DIRS}
    ${EIGEN3_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIRS}
    ${OpenCV_INCLUDE_DIRS}
    ${ONNXRuntime_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/neural-extensions/include
)

# Link libraries
target_link_libraries(colmap-neural
    PRIVATE
    COLMAP::COLMAP
    Eigen3::Eigen
    ${Boost_LIBRARIES}
    ${OpenCV_LIBS}
    ${ONNXRuntime_LIBRARIES}
    glog::glog
    neural_extensions
)

# For Apple Silicon, add Metal support
if(APPLE AND WITH_METAL)
    target_link_libraries(colmap-neural PRIVATE ${METAL_LIBRARIES})
    target_compile_definitions(colmap-neural PRIVATE WITH_METAL)
endif()

# Copy config files to build directory
configure_file(
    ${CMAKE_SOURCE_DIR}/config/config.ini 
    ${CMAKE_BINARY_DIR}/config/config.ini 
    COPYONLY
)

# Installation
install(TARGETS colmap-neural DESTINATION bin)
install(FILES ${CMAKE_SOURCE_DIR}/config/config.ini DESTINATION etc/colmap-neural)

# Print ONNX Runtime configuration
message(STATUS "ONNX Runtime configuration:")
message(STATUS "  Version: ${ONNXRUNTIME_VERSION}")
message(STATUS "  Include Dirs: ${ONNXRuntime_INCLUDE_DIRS}")
message(STATUS "  Libraries: ${ONNXRuntime_LIBRARIES}")

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