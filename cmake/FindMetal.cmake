# cmake/FindMetal.cmake
# Find Apple's Metal framework and related frameworks

if(NOT APPLE)
    message(FATAL_ERROR "Metal is only available on Apple platforms")
    return()
endif()

# Find Metal framework
find_path(Metal_INCLUDE_DIR
    NAMES Metal/Metal.h
    PATHS ${CMAKE_OSX_SYSROOT}/System/Library/Frameworks
    PATH_SUFFIXES Metal.framework/Headers
)

# Find MetalKit framework
find_path(MetalKit_INCLUDE_DIR
    NAMES MetalKit/MetalKit.h
    PATHS ${CMAKE_OSX_SYSROOT}/System/Library/Frameworks
    PATH_SUFFIXES MetalKit.framework/Headers
)

# Find CoreML framework
find_path(CoreML_INCLUDE_DIR
    NAMES CoreML/CoreML.h
    PATHS ${CMAKE_OSX_SYSROOT}/System/Library/Frameworks
    PATH_SUFFIXES CoreML.framework/Headers
)

# Find the actual frameworks
find_library(Metal_LIBRARY
    NAMES Metal
    PATHS ${CMAKE_OSX_SYSROOT}/System/Library/Frameworks
)

find_library(MetalKit_LIBRARY
    NAMES MetalKit
    PATHS ${CMAKE_OSX_SYSROOT}/System/Library/Frameworks
)

find_library(CoreML_LIBRARY
    NAMES CoreML
    PATHS ${CMAKE_OSX_SYSROOT}/System/Library/Frameworks
)

# Set Metal_FOUND if all required components are found
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Metal
    REQUIRED_VARS 
    Metal_INCLUDE_DIR 
    Metal_LIBRARY
    MetalKit_INCLUDE_DIR
    MetalKit_LIBRARY
)

if(Metal_FOUND)
    set(Metal_INCLUDE_DIRS 
        ${Metal_INCLUDE_DIR} 
        ${MetalKit_INCLUDE_DIR}
        ${CoreML_INCLUDE_DIR}
    )
    set(Metal_LIBRARIES 
        ${Metal_LIBRARY} 
        ${MetalKit_LIBRARY}
        ${CoreML_LIBRARY}
    )
    
    message(STATUS "Found Metal Framework: ${Metal_LIBRARY}")
    message(STATUS "Found MetalKit Framework: ${MetalKit_LIBRARY}")
    message(STATUS "Found CoreML Framework: ${CoreML_LIBRARY}")
    
    # Add a target for Metal
    if(NOT TARGET Metal::Metal)
        add_library(Metal::Metal INTERFACE IMPORTED)
        set_target_properties(Metal::Metal PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${Metal_INCLUDE_DIRS}"
            INTERFACE_LINK_LIBRARIES "${Metal_LIBRARIES}"
        )
    endif()
endif()

mark_as_advanced(
    Metal_INCLUDE_DIR
    Metal_LIBRARY
    MetalKit_INCLUDE_DIR
    MetalKit_LIBRARY
    CoreML_INCLUDE_DIR
    CoreML_LIBRARY
)