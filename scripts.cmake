include(${CMAKE_SCRIPTS_DIRECTORY}/functions_directory.cmake)
include(${CMAKE_SCRIPTS_DIRECTORY}/functions_project.cmake)

set(PROJECT_BIN_DIR "bin")
set(PROJECT_LIB_DIR "lib")

if (MSVC)
# generate pdb files in release build
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Zi" CACHE STRING "" FORCE)
  set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF" CACHE STRING "" FORCE)
  set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF" CACHE STRING "" FORCE)

  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17")
else()
  set(CMAKE_CXX_STANDARD 17)
endif()

# update output directories, see http://stackoverflow.com/questions/7229571/cmake-visual-studio-debug-folder
# First for the generic no-config case (e.g. with mingw)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${PROJECT_BIN_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${PROJECT_LIB_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${PROJECT_LIB_DIR})
# Second, for multi-config builds (e.g. msvc)
foreach(OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
  string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${PROJECT_BIN_DIR})
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${PROJECT_LIB_DIR})
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/${PROJECT_LIB_DIR})
endforeach(OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES)

if (WIN32)
  option(BUILD_ENABLE_CONSOLE "Builds a console application (Windows only)" ON)
endif()
