function(find_required_library)

  find_package(GTest)

  if (NOT EXISTS ${GTEST_LIBRARY_DEBUG})
    if (EXISTS ${GTEST_LIBRARY})
      unset(GTEST_LIBRARY_DEBUG CACHE)
      set(GTEST_LIBRARY_DEBUG ${GTEST_LIBRARY} CACHE STRING "")
    endif()
  endif()

  if (NOT EXISTS ${GTEST_MAIN_LIBRARY_DEBUG})
    if (EXISTS ${GTEST_MAIN_LIBRARY})
      unset(GTEST_MAIN_LIBRARY_DEBUG CACHE)
      set(GTEST_MAIN_LIBRARY_DEBUG ${GTEST_MAIN_LIBRARY} CACHE STRING "")
    endif()
  endif()

endfunction()

function(required_library_exists BOOL)

  set(${BOOL} TRUE PARENT_SCOPE)
  if (NOT EXISTS ${GTEST_INCLUDE_DIR})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()
  if (NOT EXISTS ${GTEST_LIBRARY})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()
  if (NOT EXISTS ${GTEST_LIBRARY_DEBUG})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()
  if (NOT EXISTS ${GTEST_MAIN_LIBRARY})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()
  if (NOT EXISTS ${GTEST_MAIN_LIBRARY_DEBUG})
    set(${BOOL} FALSE PARENT_SCOPE)
  endif()

endfunction()

function(get_include_directories OUTPUT)

  get_filename_component(TMP_INCLUDE_DIRECTORY ${GTEST_INCLUDE_DIR} REALPATH)
  set_parent_scope(${OUTPUT} ${TMP_INCLUDE_DIRECTORY})

endfunction()