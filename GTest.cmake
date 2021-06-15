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

macro(find_required_binary BINARY_NAME BINARY_POSTFIX)

  if(NOT DEFINED ${BINARY_NAME}_BINARY${BINARY_POSTFIX})
    set(${BINARY_NAME}_BINARY${BINARY_POSTFIX} "" CACHE STRING "")
  endif()

  if (NOT EXISTS ${${BINARY_NAME}_BINARY${BINARY_POSTFIX}})
    if (EXISTS ${${BINARY_NAME}_LIBRARY${BINARY_POSTFIX}})
      get_filename_component(TMP_LIBRARY_PATH ${${BINARY_NAME}_LIBRARY${BINARY_POSTFIX}} DIRECTORY)
      get_filename_component(TMP_LIBRARY_FILENAME ${${BINARY_NAME}_LIBRARY${BINARY_POSTFIX}} NAME_WLE)

      if (EXISTS ${TMP_LIBRARY_PATH}/${TMP_LIBRARY_FILENAME}.dll)
        unset(${BINARY_NAME}_BINARY${BINARY_POSTFIX} CACHE)
        set(${BINARY_NAME}_BINARY${BINARY_POSTFIX} ${TMP_LIBRARY_PATH}/${TMP_LIBRARY_FILENAME}.dll CACHE STRING "")
      endif()
    endif()
  endif()

endmacro()

function(find_required_binaries)

  find_required_binary(GTEST "_DEBUG")
  find_required_binary(GTEST "")
  find_required_binary(GTEST_MAIN "_DEBUG")
  find_required_binary(GTEST_MAIN "")

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

  get_filename_component(TMP_INCLUDE_DIRECTORY ${GTEST_INCLUDE_DIR} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_INCLUDE_DIRECTORY})

endfunction()

function(get_library_files_debug OUTPUT)

  get_filename_component(TMP_GTEST_LIBRARY_DEBUG ${GTEST_LIBRARY_DEBUG} ABSOLUTE)
  get_filename_component(TMP_MAIN_LIBRARY_DEBUG ${GTEST_MAIN_LIBRARY_DEBUG} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_GTEST_LIBRARY_DEBUG} ${TMP_MAIN_LIBRARY_DEBUG})

endfunction()

function(get_library_files_release OUTPUT)

  get_filename_component(TMP_GTEST_LIBRARY ${GTEST_LIBRARY} ABSOLUTE)
  get_filename_component(TMP_MAIN_LIBRARY ${GTEST_MAIN_LIBRARY} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_GTEST_LIBRARY} ${TMP_MAIN_LIBRARY})

endfunction()

macro(add_binary_file OUTPUT BINARY_NAME BINARY_POSTFIX)

  if(EXISTS ${${BINARY_NAME}_BINARY${BINARY_POSTFIX}})
    set_parent_scope(${OUTPUT} ${${OUTPUT}} ${${BINARY_NAME}_BINARY${BINARY_POSTFIX}})
  endif()

endmacro()

function(get_binary_files OUTPUT)

  set_parent_scope(${OUTPUT} "")
  add_binary_file(${OUTPUT} GTEST "_DEBUG")
  add_binary_file(${OUTPUT} GTEST "")
  add_binary_file(${OUTPUT} GTEST_MAIN "_DEBUG")
  add_binary_file(${OUTPUT} GTEST_MAIN "")

endfunction()