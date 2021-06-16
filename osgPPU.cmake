macro(find_required_library)

  if(NOT DEFINED OSGPPU_INCLUDE_DIRECTORY)
    set(OSGPPU_INCLUDE_DIRECTORY "" CACHE STRING "")
  endif()
  if(NOT DEFINED OSGPPU_LIBRARY_DEBUG)
    set(OSGPPU_LIBRARY_DEBUG "" CACHE STRING "")
  endif()
  if(NOT DEFINED OSGPPU_LIBRARY_RELEASE)
    set(OSGPPU_LIBRARY_RELEASE "" CACHE STRING "")
  endif()

  if (NOT EXISTS ${OSGPPU_LIBRARY_DEBUG})
    if (EXISTS ${OSGPPU_LIBRARY_RELEASE})
      unset(OSGPPU_LIBRARY_DEBUG CACHE)
      set(OSGPPU_LIBRARY_DEBUG ${OSGPPU_LIBRARY_RELEASE} CACHE STRING "")
    endif()
  endif()

endmacro()

function(find_required_binaries)

  if(NOT DEFINED OSGPPU_BINARY_RELEASE)
    set(OSGPPU_BINARY_RELEASE "" CACHE STRING "")
  endif()
  if(NOT DEFINED OSGPPU_BINARY_DEBUG)
    set(OSGPPU_BINARY_DEBUG "" CACHE STRING "")
  endif()

  if (NOT EXISTS ${OSGPPU_BINARY_DEBUG})
    if (EXISTS ${OSGPPU_BINARY_RELEASE})
      unset(OSGPPU_BINARY_DEBUG CACHE)
      set(OSGPPU_BINARY_DEBUG ${OSGPPU_BINARY_RELEASE} CACHE STRING "")
    endif()
  endif()

endfunction()

function(required_library_exists BOOL)

  set(${BOOL} TRUE PARENT_SCOPE)
  if (NOT EXISTS ${OSGPPU_LIBRARY_DEBUG})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()
  if (NOT EXISTS ${OSGPPU_LIBRARY_RELEASE})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()
  if (NOT EXISTS ${OSGPPU_INCLUDE_DIRECTORY})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()

endfunction()

function(get_include_directories OUTPUT)

  get_filename_component(TMP_INCLUDE_DIRECTORY ${OSGPPU_INCLUDE_DIRECTORY} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_INCLUDE_DIRECTORY})

endfunction()

function(get_library_files_debug OUTPUT)

  get_filename_component(TMP_OSGPPU_LIBRARY_DEBUG ${OSGPPU_LIBRARY_DEBUG} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_OSGPPU_LIBRARY_DEBUG})

endfunction()

function(get_library_files_release OUTPUT)

  get_filename_component(TMP_OSGPPU_LIBRARY_RELEASE ${OSGPPU_LIBRARY_RELEASE} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_OSGPPU_LIBRARY_RELEASE})

endfunction()

function(get_binary_files OUTPUT)

  set_parent_scope(${OUTPUT} "")
  if (EXISTS ${OSGPPU_BINARY_RELEASE})
    get_filename_component(TMP_OSGPPU_BINARY_RELEASE ${OSGPPU_BINARY_RELEASE} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_OSGPPU_BINARY_RELEASE})
  endif()
  if (EXISTS ${OSGPPU_BINARY_DEBUG})
    get_filename_component(TMP_OSGPPU_BINARY_DEBUG ${OSGPPU_BINARY_DEBUG} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_OSGPPU_BINARY_DEBUG})
  endif()

endfunction()