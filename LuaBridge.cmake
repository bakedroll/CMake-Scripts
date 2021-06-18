macro(find_required_library)

  set(LUABRIDGE_INCLUDE_DIR "" CACHE STRING "")

endmacro()

function(required_library_exists BOOL)

  set(${BOOL} TRUE PARENT_SCOPE)
  if (NOT EXISTS ${LUABRIDGE_INCLUDE_DIR})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()

endfunction()

function(get_include_directories OUTPUT)

  get_filename_component(TMP_LUABRIDGE_INCLUDE_DIR ${LUABRIDGE_INCLUDE_DIR} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_LUABRIDGE_INCLUDE_DIR})

endfunction()