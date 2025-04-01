# Script to apply patches to COLMAP source code if needed
# This is useful when building COLMAP from source and modifications are required

message(STATUS "Loading COLMAP patching functionality...")

# Function to apply a patch
function(apply_patch patch_file colmap_dir)
    if(EXISTS "${patch_file}")
        message(STATUS "Applying patch: ${patch_file}")
        execute_process(
            COMMAND patch -p1 -i "${patch_file}"
            WORKING_DIRECTORY "${colmap_dir}"
            RESULT_VARIABLE patch_result
        )
        
        if(NOT patch_result EQUAL 0)
            message(WARNING "Failed to apply patch: ${patch_file}")
        else()
            message(STATUS "Patch applied successfully: ${patch_file}")
        endif()
    else()
        message(WARNING "Patch file not found: ${patch_file}")
    endif()
endfunction()

# Main patching function that gets called from the parent CMakeLists.txt
function(patch_colmap_files colmap_dir)
  message(STATUS "Patching COLMAP files at: ${colmap_dir}")
  
  # Check for M4-specific optimizations that need to be applied
  if(APPLE)
    # Check if we're on Apple Silicon
    execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE ARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    if(ARCH STREQUAL "arm64")
        message(STATUS "Detected Apple Silicon architecture")
        
        # Apply Metal optimization patches if they exist
        apply_patch("${CMAKE_SOURCE_DIR}/patches/colmap_metal_optimization.patch" "${colmap_dir}")
        
        # Add Metal-specific compilation flags
        # Note: Using a more compatible optimization flag instead of -mcpu=apple-m4
        # which might not be supported by all compilers
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3" PARENT_SCOPE)
    endif()
  endif()
  
  # Apply any additional patches needed for COLMAP
  # apply_patch("${CMAKE_SOURCE_DIR}/patches/fix_compilation_error.patch" "${colmap_dir}")
endfunction()