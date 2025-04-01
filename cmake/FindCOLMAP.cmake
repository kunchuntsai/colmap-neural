# FindCOLMAP.cmake - Find COLMAP libraries and includes
#
# This module defines:
#  COLMAP_FOUND - True if COLMAP was found
#  COLMAP_INCLUDE_DIRS - COLMAP include directories
#  COLMAP_LIBRARIES - COLMAP libraries to link against
#
# The following variables can be set as arguments:
#  COLMAP_ROOT_DIR - Root directory for COLMAP installation

# Set a default root directory if not specified
if(NOT DEFINED COLMAP_ROOT_DIR)
    if(DEFINED ENV{COLMAP_ROOT_DIR})
        set(COLMAP_ROOT_DIR $ENV{COLMAP_ROOT_DIR})
    else()
        # Check common installation directories
        if(WIN32)
            set(COLMAP_ROOT_DIR "C:/Program Files/COLMAP")
        elseif(APPLE)
            set(COLMAP_ROOT_DIR "/usr/local")
        else()
            set(COLMAP_ROOT_DIR "/usr/local")
        endif()
    endif()
endif()

# Try to find COLMAP
find_path(COLMAP_INCLUDE_DIR
    NAMES colmap/util/version.h
    PATHS
        ${COLMAP_ROOT_DIR}/include
        /usr/include
        /usr/local/include
)

# Platform-specific library name
if(WIN32)
    find_library(COLMAP_LIBRARY
        NAMES colmap
        PATHS
            ${COLMAP_ROOT_DIR}/lib
            ${COLMAP_ROOT_DIR}/bin
    )
else()
    find_library(COLMAP_LIBRARY
        NAMES colmap
        PATHS
            ${COLMAP_ROOT_DIR}/lib
            /usr/lib
            /usr/local/lib
    )
endif()

# Set output variables
set(COLMAP_INCLUDE_DIRS ${COLMAP_INCLUDE_DIR})
set(COLMAP_LIBRARIES ${COLMAP_LIBRARY})

# Handle standard find_package arguments
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(COLMAP 
    DEFAULT_MSG
    COLMAP_LIBRARY COLMAP_INCLUDE_DIR
)

# Mark as advanced
mark_as_advanced(COLMAP_INCLUDE_DIR COLMAP_LIBRARY)

# If COLMAP was found, add its dependencies
if(COLMAP_FOUND)
    find_package(Eigen3 REQUIRED)
    find_package(Boost REQUIRED COMPONENTS filesystem program_options system)
    find_package(Ceres REQUIRED)
    find_package(gflags REQUIRED)
    find_package(glog REQUIRED)
    
    # Add COLMAP dependencies to libraries
    list(APPEND COLMAP_LIBRARIES
        Eigen3::Eigen
        ${Boost_LIBRARIES}
        ${CERES_LIBRARIES}
        gflags
        glog
    )
    
    # Platform-specific dependencies
    if(APPLE)
        find_package(OpenGL REQUIRED)
        list(APPEND COLMAP_LIBRARIES ${OpenGL_LIBRARIES})
    endif()
endif()