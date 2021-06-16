function(required_library_exists BOOL)

  set(${BOOL} TRUE PARENT_SCOPE)
  if (NOT DEFINED OPENGL_gl_LIBRARY)
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()

endfunction()

function(get_library_files_release OUTPUT)

  set_parent_scope(${OUTPUT} ${OPENGL_gl_LIBRARY})

endfunction()
