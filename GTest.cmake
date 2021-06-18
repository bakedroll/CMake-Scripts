macro(gtest_set_libraries GTEST_LIB)

  foreach(LIBRARY_FILE IN ITEMS ${${GTEST_LIB}_LIBRARIES})

    if (${LIBRARY_FILE} STREQUAL "debug")
      set(LAST_CONFIG "_DEBUG")
    elseif(${LIBRARY_FILE} STREQUAL "optimized")
      set(LAST_CONFIG "")
    else()
      if (NOT EXISTS ${${GTEST_LIB}_LIBRARY_${LAST_CONFIG}})
        unset(${GTEST_LIB}_LIBRARY${LAST_CONFIG} CACHE)
        set(${GTEST_LIB}_LIBRARY${LAST_CONFIG} ${LIBRARY_FILE} CACHE STRING "")
      endif()
    endif()
    
  endforeach()

endmacro()

macro(find_required_library)

  find_package(GTest)

  if (${GTest_FOUND} STREQUAL "TRUE")
    gtest_set_libraries(GTEST)
    gtest_set_libraries(GTEST_MAIN)

    if (NOT EXISTS ${GTEST_INCLUDE_DIR})
      set(TMP_INCLUDE_DIRS "")
      foreach(TMP_INCLUDE_DIR IN ITEMS ${GTEST_INCLUDE_DIRS})
        get_filename_component(TMP_INCLUDE_DIR ${TMP_INCLUDE_DIR} ABSOLUTE)
        set(TMP_INCLUDE_DIRS ${TMP_INCLUDE_DIRS} ${TMP_INCLUDE_DIR})
      endforeach()
      unset(GTEST_INCLUDE_DIR CACHE)
      set(GTEST_INCLUDE_DIR ${TMP_INCLUDE_DIRS} CACHE STRING "")
    endif()
  endif()

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

endmacro()

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

macro(find_required_binaries)

  find_required_binary(GTEST "_DEBUG")
  find_required_binary(GTEST "")
  find_required_binary(GTEST_MAIN "_DEBUG")
  find_required_binary(GTEST_MAIN "")

endmacro()

function(required_library_exists BOOL)

  set(${BOOL} ${GTest_FOUND} PARENT_SCOPE)

endfunction()

function(get_include_directories OUTPUT)

  if (DEFINED GTEST_INCLUDE_DIR)
    set_parent_scope(${OUTPUT} ${GTEST_INCLUDE_DIR})
  endif()

endfunction()

macro(add_gtest_library OUTPUT GTEST_LIB LIB_POSTFIX)

  if (EXISTS ${${GTEST_LIB}_LIBRARY${LIB_POSTFIX}})
    get_filename_component(TMP_GTEST_LIBRARY ${${GTEST_LIB}_LIBRARY${LIB_POSTFIX}} ABSOLUTE)
  elseif(DEFINED ${GTEST_LIB}_LIBRARY${LIB_POSTFIX})
    set(TMP_GTEST_LIBRARY ${${GTEST_LIB}_LIBRARY${LIB_POSTFIX}})
  else()
    set(TMP_GTEST_LIBRARY "")
  endif()

  set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_GTEST_LIBRARY})

endmacro()

function(get_library_files_debug OUTPUT)

  add_gtest_library(${OUTPUT} GTEST "_DEBUG")
  add_gtest_library(${OUTPUT} GTEST_MAIN "_DEBUG")

endfunction()

function(get_library_files_release OUTPUT)

  add_gtest_library(${OUTPUT} GTEST "")
  add_gtest_library(${OUTPUT} GTEST_MAIN "")

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