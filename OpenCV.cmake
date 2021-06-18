macro(find_opencv_file OPENCV_FILE_DIRECTORY OPENCV_MODULE CONFIGURATION_POSTFIX FILE_TYPE)

  if (${FILE_TYPE} STREQUAL "LIBRARY")
    set(OPENCV_MODULE_FILE_EXTENSION "lib")
  elseif (${FILE_TYPE} STREQUAL "BINARY")
    set(OPENCV_MODULE_FILE_EXTENSION "dll")
  endif()

  file(GLOB FILES_LIB "${OPENCV_FILE_DIRECTORY}/*${OPENCV_MODULE}[0-999]*.${OPENCV_MODULE_FILE_EXTENSION}")

  list(LENGTH FILES_LIB FILES_LIB_LENGTH)
  if (${FILES_LIB_LENGTH} EQUAL 1)
    set(OPENCV_${OPENCV_MODULE}_${FILE_TYPE}_${CONFIGURATION_POSTFIX} ${FILES_LIB})
  elseif (${FILES_LIB_LENGTH} GREATER 1)
    message(WARNING "Multiple files found for OpenCV library module ${OPENCV_MODULE}")
  endif()

endmacro()

macro(find_opencv_module_files OPENCV_FILE_DIRECTORY CONFIGURATION_POSTFIX FILE_TYPE)
  
  foreach(MODULE IN ITEMS ${ARGN})
   find_opencv_file(${OPENCV_FILE_DIRECTORY} ${MODULE} ${CONFIGURATION_POSTFIX} ${FILE_TYPE})
  endforeach()

endmacro()

macro(find_required_library)

  set(OPENCV_INCLUDE_DIRECTORY "" CACHE STRING "")
  set(OPENCV_LIBRARY_DIRECTORY "" CACHE STRING "")
  set(OPENCV_LIBRARY_DIRECTORY_DEBUG "" CACHE STRING "")

  if (EXISTS ${OPENCV_LIBRARY_DIRECTORY})
    get_filename_component(TMP_OPENCV_FILE_DIRECTORY ${OPENCV_LIBRARY_DIRECTORY} ABSOLUTE)
    find_opencv_module_files(${TMP_OPENCV_FILE_DIRECTORY} RELEASE LIBRARY ${ARGN})
  endif()

  if (EXISTS ${OPENCV_LIBRARY_DIRECTORY_DEBUG})
    get_filename_component(TMP_OPENCV_FILE_DIRECTORY ${OPENCV_LIBRARY_DIRECTORY_DEBUG} ABSOLUTE)
    find_opencv_module_files(${TMP_OPENCV_FILE_DIRECTORY} DEBUG LIBRARY ${ARGN})
  endif()

  foreach(MODULE IN ITEMS ${ARGN})
    if (EXISTS ${OPENCV_${MODULE}_LIBRARY_RELEASE})
      if (NOT EXISTS ${OPENCV_${MODULE}_LIBRARY_DEBUG})
        set(OPENCV_${MODULE}_LIBRARY_DEBUG ${OPENCV_${MODULE}_LIBRARY_RELEASE})
      endif()
    endif()
  endforeach()

endmacro()

macro(find_required_binaries)

  set(OPENCV_BINARY_DIRECTORY "" CACHE STRING "")
  set(OPENCV_BINARY_DIRECTORY_DEBUG "" CACHE STRING "")

  if (EXISTS ${OPENCV_BINARY_DIRECTORY})
    get_filename_component(TMP_OPENCV_FILE_DIRECTORY ${OPENCV_BINARY_DIRECTORY} ABSOLUTE)
    find_opencv_module_files(${TMP_OPENCV_FILE_DIRECTORY} RELEASE BINARY ${ARGN})
  endif()

  if (EXISTS ${OPENCV_BINARY_DIRECTORY_DEBUG})
    get_filename_component(TMP_OPENCV_FILE_DIRECTORY ${OPENCV_BINARY_DIRECTORY_DEBUG} ABSOLUTE)
    find_opencv_module_files(${TMP_OPENCV_FILE_DIRECTORY} DEBUG BINARY ${ARGN})
  endif()

endmacro()

function(required_library_exists BOOL)

  set(${BOOL} TRUE PARENT_SCOPE)
  if (NOT EXISTS ${OPENCV_INCLUDE_DIRECTORY})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()

  foreach(MODULE IN ITEMS ${ARGN})
    if (NOT EXISTS ${OPENCV_${MODULE}_LIBRARY_RELEASE})
      set(${BOOL} FALSE PARENT_SCOPE)
    endif()
  endforeach()

endfunction()

function(get_include_directories OUTPUT)

  get_filename_component(TMP_OPENCV_INCLUDE_DIRECTORY ${OPENCV_INCLUDE_DIRECTORY} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_OPENCV_INCLUDE_DIRECTORY})

endfunction()

function(get_library_files_debug OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    get_filename_component(TMP_LIBRARY ${OPENCV_${MODULE}_LIBRARY_DEBUG} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_LIBRARY})
  endforeach()

endfunction()

function(get_library_files_release OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    get_filename_component(TMP_LIBRARY ${OPENCV_${MODULE}_LIBRARY_RELEASE} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_LIBRARY})
  endforeach()

endfunction()

function(get_binary_files OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    get_filename_component(TMP_LIBRARY_RELEASE ${OPENCV_${MODULE}_BINARY_RELEASE} ABSOLUTE)
    get_filename_component(TMP_LIBRARY_DEBUG ${OPENCV_${MODULE}_BINARY_DEBUG} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_LIBRARY_DEBUG} ${TMP_LIBRARY_RELEASE})
  endforeach()

endfunction()