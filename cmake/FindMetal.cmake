# FindMetal.cmake - Find Apple Metal framework and related libraries
#
# This module defines:
#  METAL_FOUND - True if Metal was found
#  METAL_INCLUDE_DIRS - Metal include directories
#  METAL_LIBRARIES - Metal libraries to link against
#
# This will search for the following components:
#  Metal - The main Metal framework
#  MetalKit - Framework for creating Metal objects
#  MetalPerformanceShaders - High-performance GPU compute library

# Only useful on Apple platforms
if(NOT APPLE)
    set(METAL_FOUND FALSE)
    return()
endif()

# Find the Metal framework
find_library(METAL_LIBRARY Metal)
find_library(METALKIT_LIBRARY MetalKit)
find_library(MPS_LIBRARY MetalPerformanceShaders)
find_library(FOUNDATION_LIBRARY Foundation)

# Also find CoreFoundation and other related frameworks
find_library(CORE_FOUNDATION_LIBRARY CoreFoundation)
find_library(CORE_GRAPHICS_LIBRARY CoreGraphics)
find_library(CORE_TEXT_LIBRARY CoreText)
find_library(COCOA_LIBRARY Cocoa)

# Set output variables
set(METAL_LIBRARIES ${METAL_LIBRARY} ${METALKIT_LIBRARY} ${MPS_LIBRARY} ${FOUNDATION_LIBRARY})
list(APPEND METAL_LIBRARIES ${CORE_FOUNDATION_LIBRARY} ${CORE_GRAPHICS_LIBRARY} ${CORE_TEXT_LIBRARY} ${COCOA_LIBRARY})

# Set include dirs
set(METAL_INCLUDE_DIRS "")

# Check if we found everything
set(METAL_FOUND FALSE)
if(METAL_LIBRARY AND METALKIT_LIBRARY AND MPS_LIBRARY)
    set(METAL_FOUND TRUE)
    message(STATUS "Found Metal: ${METAL_LIBRARY}")
    message(STATUS "Found MetalKit: ${METALKIT_LIBRARY}")
    message(STATUS "Found MetalPerformanceShaders: ${MPS_LIBRARY}")
else()
    if(NOT METAL_LIBRARY)
        message(STATUS "Metal framework not found")
    endif()
    if(NOT METALKIT_LIBRARY)
        message(STATUS "MetalKit framework not found")
    endif()
    if(NOT MPS_LIBRARY)
        message(STATUS "MetalPerformanceShaders framework not found")
    endif()
endif()

# Handle standard find_package arguments
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Metal 
    DEFAULT_MSG
    METAL_LIBRARY
)

# Mark as advanced
mark_as_advanced(
    METAL_LIBRARY
    METALKIT_LIBRARY
    MPS_LIBRARY
    FOUNDATION_LIBRARY
    CORE_FOUNDATION_LIBRARY
    CORE_GRAPHICS_LIBRARY
    CORE_TEXT_LIBRARY
    COCOA_LIBRARY
)

# Function to check if Metal is available at runtime
function(check_metal_availability)
    # Create a simple test program
    set(metal_test_source "
    #include <Metal/Metal.h>
    int main() {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        return device ? 0 : 1;
    }
    ")
    
    # Try to compile and run the test program
    file(WRITE "${CMAKE_BINARY_DIR}/metal_test.mm" "${metal_test_source}")
    try_run(
        run_result compile_result
        "${CMAKE_BINARY_DIR}"
        "${CMAKE_BINARY_DIR}/metal_test.mm"
        CMAKE_FLAGS "-DINCLUDE_DIRECTORIES=${METAL_INCLUDE_DIRS}" "-DLINK_LIBRARIES=${METAL_LIBRARIES}"
        COMPILE_OUTPUT_VARIABLE compile_output
        RUN_OUTPUT_VARIABLE run_output
    )
    
    # Check results
    if(compile_result AND run_result EQUAL 0)
        message(STATUS "Metal is available at runtime")
        set(METAL_AVAILABLE TRUE PARENT_SCOPE)
    else()
        message(STATUS "Metal is not available at runtime")
        if(NOT compile_result)
            message(STATUS "Compilation failed: ${compile_output}")
        endif()
        set(METAL_AVAILABLE FALSE PARENT_SCOPE)
    endif()
    
    # Clean up
    file(REMOVE "${CMAKE_BINARY_DIR}/metal_test.mm")
endfunction()