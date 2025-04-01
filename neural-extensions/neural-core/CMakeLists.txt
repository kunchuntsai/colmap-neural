# Neural Core CMakeLists.txt

# Define source files
set(SOURCES
    src/model_loader.cc
    src/mps_utils.cc
    src/registry.cc
    src/neural_interface.cc
)

# Define header files
set(HEADERS
    include/model_loader.h
    include/mps_utils.h
    include/registry.h
    include/neural_interface.h
)

# Add library
add_library(neural-core STATIC ${SOURCES} ${HEADERS})

# Include directories
target_include_directories(neural-core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}
    ${COLMAP_INCLUDE_DIRS}
    ${TORCH_INCLUDE_DIRS}
    ${OpenCV_INCLUDE_DIRS}
)

# Link dependencies
target_link_libraries(neural-core
    COLMAP::COLMAP
    ${TORCH_LIBRARIES}
    ${OpenCV_LIBS}
)

# Add Metal support if available
if(APPLE AND WITH_METAL AND Metal_FOUND)
    target_compile_definitions(neural-core PRIVATE WITH_METAL)
    target_link_libraries(neural-core ${Metal_LIBRARY})
    
    if(DEFINED METAL_PERFORMANCE_SHADERS)
        target_compile_definitions(neural-core PRIVATE WITH_MPS)
        target_link_libraries(neural-core ${METAL_PERFORMANCE_SHADERS})
    endif()
    
    if(DEFINED ACCELERATE_FRAMEWORK)
        target_link_libraries(neural-core ${ACCELERATE_FRAMEWORK})
    endif()
    
    if(DEFINED CORE_ML)
        target_link_libraries(neural-core ${CORE_ML})
    endif()
endif()

# Apple M4 Pro optimizations
if(APPLE AND WITH_METAL)
    target_compile_options(neural-core PRIVATE -O3 -mcpu=apple-m4)
endif()