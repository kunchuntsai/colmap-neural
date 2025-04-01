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
    
    # Create external directory if it doesn't exist
    if(NOT EXISTS ${COLMAP_SOURCE_DIR} AND EXISTS ${CMAKE_SOURCE_DIR}/external)
        file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/external)
    endif()
    
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
    
    # Add Apple M4 Pro specific optimizations
    if(APPLE AND WITH_METAL)
        # Add optimization flags separately to avoid parsing issues
        list(APPEND COLMAP_CMAKE_ARGS -DCMAKE_CXX_FLAGS="-O3")
        list(APPEND COLMAP_CMAKE_ARGS -DCMAKE_CXX_FLAGS_RELEASE="-O3")
        
        # Check if we can detect Apple Silicon before adding M4-specific flags
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
    
    # The actual library paths will be configured in the script
    # but we'll set include directories here for convenience
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

# Find other dependencies
find_package(Boost REQUIRED COMPONENTS program_options filesystem system)
find_package(Eigen3 REQUIRED)
find_package(OpenCV REQUIRED)
find_package(glog REQUIRED)
find_package(gflags REQUIRED)

# Add the neural-extensions if they exist
if(EXISTS ${CMAKE_SOURCE_DIR}/neural-extensions)
    message(STATUS "Adding neural-extensions directory")
    add_subdirectory(neural-extensions)
endif()

# Add subdirectories
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