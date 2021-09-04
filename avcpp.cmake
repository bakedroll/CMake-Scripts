macro(find_required_library)

  set(AVCPP_INCLUDE_DIRECTORY "" CACHE PATH "")
  set(AVCPP_LIBRARY "" CACHE PATH "")
  set(AVCPP_LIBRARY_DEBUG "" CACHE PATH "")
  set(AVCPP_BINARY "" CACHE PATH "")
  set(AVCPP_BINARY_DEBUG "" CACHE PATH "")

  if (NOT EXISTS ${AVCPP_LIBRARY_DEBUG})
    if (EXISTS ${AVCPP_LIBRARY})
      unset(AVCPP_LIBRARY_DEBUG CACHE)
      set(AVCPP_LIBRARY_DEBUG ${AVCPP_LIBRARY} CACHE PATH "")
    endif()
  endif()

  if (NOT EXISTS ${AVCPP_BINARY_DEBUG})
    if (EXISTS ${AVCPP_BINARY})
      unset(AVCPP_BINARY_DEBUG CACHE)
      set(AVCPP_BINARY_DEBUG ${AVCPP_BINARY} CACHE PATH "")
    endif()
  endif()

endmacro()

function(required_library_exists BOOL)

  set(${BOOL} FALSE PARENT_SCOPE)
  if (EXISTS "${AVCPP_INCLUDE_DIRECTORY}" AND
    EXISTS "${AVCPP_LIBRARY}" AND
    EXISTS "${AVCPP_LIBRARY_DEBUG}")

    set(${BOOL} TRUE PARENT_SCOPE)
  endif()

endfunction()

function(get_include_directories OUTPUT)

  get_filename_component(TMP_INCLUDE_DIRECTORY ${AVCPP_INCLUDE_DIRECTORY} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_INCLUDE_DIRECTORY})

endfunction()

function(get_library_files_debug OUTPUT)

  get_filename_component(TMP_AVCPP_LIBRARY_DEBUG ${AVCPP_LIBRARY_DEBUG} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_AVCPP_LIBRARY_DEBUG})

endfunction()

function(get_library_files_release OUTPUT)

  get_filename_component(TMP_AVCPP_LIBRARY ${AVCPP_LIBRARY} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_AVCPP_LIBRARY})

endfunction()

function(get_binary_files OUTPUT)

  set(AVCPP_BINARY_FILES
    ${AVCPP_BINARY}
    ${AVCPP_BINARY_DEBUG})

  foreach(BIN_FILE IN ITEMS ${AVCPP_BINARY_FILES})
    get_filename_component(TMP_BIN_FILE ${BIN_FILE} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_BIN_FILE})
  endforeach()

endfunction()