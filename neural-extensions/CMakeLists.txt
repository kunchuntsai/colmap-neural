# neural-extensions/CMakeLists.txt
cmake_minimum_required(VERSION 3.20)

# Set CMake policies
if(POLICY CMP0144)
  cmake_policy(SET CMP0144 NEW)
endif()

# Add the neural-core subdirectory
add_subdirectory(neural-core)

# If you already have these directories, you can add them too
# but they can be empty or with minimal implementations for Phase 1
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/feature")
  add_subdirectory(feature)
endif()

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/matcher")
  add_subdirectory(matcher)
endif()

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/mvs")
  add_subdirectory(mvs)
endif()