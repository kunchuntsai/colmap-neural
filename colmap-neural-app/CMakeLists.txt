cmake_minimum_required(VERSION 3.10)
project(colmap-neural-app VERSION 0.1.0)

# Include the generated ConfigureCOLMAP.cmake file
include(${CMAKE_BINARY_DIR}/cmake/ConfigureCOLMAP.cmake)

# Find dependencies
find_package(gflags REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(Boost REQUIRED COMPONENTS filesystem system program_options)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${COLMAP_INCLUDE_DIRS}
    ${EIGEN3_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIRS}
)

# Add source files
set(SOURCES
    src/main.cc
    # Add other source files as they're created
)

# Add executable
add_executable(colmap-neural ${SOURCES})

# Link libraries
target_link_libraries(colmap-neural
    ${COLMAP_LIBRARIES}
    gflags
    Eigen3::Eigen
    ${Boost_LIBRARIES}
)

# For Apple M4, add Metal support
if(APPLE AND WITH_METAL)
    # Use the FindMetal package we created
    find_package(Metal REQUIRED)
    if(METAL_FOUND)
        target_link_libraries(colmap-neural ${METAL_LIBRARIES})
        target_compile_definitions(colmap-neural PRIVATE WITH_METAL)
    endif()
endif()

# If neural extensions are available, link against them
if(TARGET neural_extensions)
    target_link_libraries(colmap-neural neural_extensions)
endif()

# Installation
install(TARGETS colmap-neural DESTINATION bin)