# COLMAP Neural App CMakeLists.txt

cmake_minimum_required(VERSION 3.20)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Define sources for the main application
set(SOURCES
    src/main.cc
)

# Create executable
add_executable(colmap-neural ${SOURCES})

# Include directories
target_include_directories(colmap-neural PUBLIC
    ${CMAKE_SOURCE_DIR}
    ${COLMAP_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIRS}
    ${EIGEN3_INCLUDE_DIR}
)

# Link libraries
target_link_libraries(colmap-neural
    COLMAP::COLMAP
    neural-extensions
    ${Boost_LIBRARIES}
    Eigen3::Eigen
    glog::glog
    gflags::gflags
)

# Add Metal support if available
if(APPLE AND WITH_METAL AND Metal_FOUND)
    target_compile_definitions(colmap-neural PRIVATE WITH_METAL)
    target_link_libraries(colmap-neural ${Metal_LIBRARY})
    
    if(DEFINED METAL_PERFORMANCE_SHADERS)
        target_compile_definitions(colmap-neural PRIVATE WITH_MPS)
        target_link_libraries(colmap-neural ${METAL_PERFORMANCE_SHADERS})
    endif()
    
    if(DEFINED ACCELERATE_FRAMEWORK)
        target_link_libraries(colmap-neural ${ACCELERATE_FRAMEWORK})
    endif()
    
    if(DEFINED CORE_ML)
        target_link_libraries(colmap-neural ${CORE_ML})
    endif()
endif()

# Define compile options optimized for Apple M4 Pro
if(APPLE AND WITH_METAL)
    target_compile_options(colmap-neural PRIVATE -O3 -mcpu=apple-m4)
endif()

# Install rules
install(TARGETS colmap-neural
    RUNTIME DESTINATION bin
)