macro(find_required_library)

  set(LUA_LIBRARY_DEBUG "" CACHE STRING "")
  find_package(Lua)

  if (NOT EXISTS ${LUA_LIBRARY_DEBUG})
    if (EXISTS ${LUA_LIBRARY})
      unset(LUA_LIBRARY_DEBUG CACHE)
      set(LUA_LIBRARY_DEBUG ${LUA_LIBRARY} CACHE STRING "")
    endif()
  endif()

endmacro()

function(required_library_exists BOOL)

  set(${BOOL} TRUE PARENT_SCOPE)
  if (NOT EXISTS ${LUA_LIBRARY_DEBUG})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()
  if (NOT EXISTS ${LUA_LIBRARY})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()
  if (NOT EXISTS ${LUA_INCLUDE_DIR})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()

endfunction()

function(get_include_directories OUTPUT)

  get_filename_component(TMP_INCLUDE_DIRECTORY ${LUA_INCLUDE_DIR} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_INCLUDE_DIRECTORY})

endfunction()

function(get_library_files_debug OUTPUT)

  get_filename_component(TMP_OSGPPU_LIBRARY_DEBUG ${LUA_LIBRARY_DEBUG} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_OSGPPU_LIBRARY_DEBUG})

endfunction()

function(get_library_files_release OUTPUT)

  get_filename_component(TMP_OSGPPU_LIBRARY_RELEASE ${LUA_LIBRARY} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_OSGPPU_LIBRARY_RELEASE})

endfunction()