function(find_required_library)

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

  get_filename_component(TMP_INCLUDE_DIRECTORY ${OSGPPU_INCLUDE_DIRECTORY} REALPATH)
  set_parent_scope(${OUTPUT} ${TMP_INCLUDE_DIRECTORY})

endfunction()