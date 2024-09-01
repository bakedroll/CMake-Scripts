string(TOUPPER ${GOOGLETEST_MODULE_NAME} GOOGLETEST_MODULE_NAME_UPPER)

macro(gtest_set_libraries LIB_NAME)

  set(LAST_CONFIG "")
  foreach(LIBRARY_FILE IN ITEMS ${${LIB_NAME}_LIBRARIES})

    if (${LIBRARY_FILE} STREQUAL "debug")
      set(LAST_CONFIG "_DEBUG")
    elseif(${LIBRARY_FILE} STREQUAL "optimized")
      set(LAST_CONFIG "")
    else()
      if (NOT EXISTS ${${LIB_NAME}_LIBRARY${LAST_CONFIG}})
        unset(${LIB_NAME}_LIBRARY${LAST_CONFIG} CACHE)
        set(${LIB_NAME}_LIBRARY${LAST_CONFIG} ${LIBRARY_FILE} CACHE STRING "")
      endif()
    endif()
    
  endforeach()

endmacro()

macro(find_required_library)

  find_package(${GOOGLETEST_MODULE_NAME})

  if (${${GOOGLETEST_MODULE_NAME}_FOUND} STREQUAL "TRUE")
    gtest_set_libraries(${GOOGLETEST_MODULE_NAME_UPPER})
    gtest_set_libraries(${GOOGLETEST_MODULE_NAME_UPPER}_MAIN)

    if (NOT EXISTS ${${GOOGLETEST_MODULE_NAME_UPPER}_INCLUDE_DIR})
      set(TMP_INCLUDE_DIRS "")
      foreach(TMP_INCLUDE_DIR IN ITEMS ${${GOOGLETEST_MODULE_NAME_UPPER}_INCLUDE_DIRS})
        get_filename_component(TMP_INCLUDE_DIR ${TMP_INCLUDE_DIR} ABSOLUTE)
        set(TMP_INCLUDE_DIRS ${TMP_INCLUDE_DIRS} ${TMP_INCLUDE_DIR})
      endforeach()
      unset(${GOOGLETEST_MODULE_NAME_UPPER}_INCLUDE_DIR CACHE)
      set(${GOOGLETEST_MODULE_NAME_UPPER}_INCLUDE_DIR ${TMP_INCLUDE_DIRS} CACHE STRING "")
    endif()
  endif()

  if (NOT EXISTS ${${GOOGLETEST_MODULE_NAME_UPPER}_LIBRARY_DEBUG})
    if (EXISTS ${${GOOGLETEST_MODULE_NAME_UPPER}_LIBRARY})
      unset(${GOOGLETEST_MODULE_NAME_UPPER}_LIBRARY_DEBUG CACHE)
      set(${GOOGLETEST_MODULE_NAME_UPPER}_LIBRARY_DEBUG ${${GOOGLETEST_MODULE_NAME_UPPER}_LIBRARY} CACHE STRING "")
    endif()
  endif()

  if (NOT EXISTS ${${GOOGLETEST_MODULE_NAME_UPPER}_MAIN_LIBRARY_DEBUG})
    if (EXISTS ${${GOOGLETEST_MODULE_NAME_UPPER}_MAIN_LIBRARY})
      unset(${GOOGLETEST_MODULE_NAME_UPPER}_MAIN_LIBRARY_DEBUG CACHE)
      set(${GOOGLETEST_MODULE_NAME_UPPER}_MAIN_LIBRARY_DEBUG ${${GOOGLETEST_MODULE_NAME_UPPER}_MAIN_LIBRARY} CACHE STRING "")
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

  find_required_binary(${GOOGLETEST_MODULE_NAME_UPPER} "_DEBUG")
  find_required_binary(${GOOGLETEST_MODULE_NAME_UPPER} "")
  find_required_binary(${GOOGLETEST_MODULE_NAME_UPPER}_MAIN "_DEBUG")
  find_required_binary(${GOOGLETEST_MODULE_NAME_UPPER}_MAIN "")

endmacro()

function(required_library_exists BOOL)

  set(${BOOL} ${${GOOGLETEST_MODULE_NAME}_FOUND} PARENT_SCOPE)

endfunction()

function(get_include_directories OUTPUT)

  if (EXISTS ${${GOOGLETEST_MODULE_NAME_UPPER}_INCLUDE_DIR})
    get_filename_component(TMP_INCLUDE_DIR ${${GOOGLETEST_MODULE_NAME_UPPER}_INCLUDE_DIR} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${TMP_INCLUDE_DIR})
  endif()

endfunction()

macro(add_gtest_library OUTPUT LIB_NAME LIB_POSTFIX)

  if (EXISTS ${${LIB_NAME}_LIBRARY${LIB_POSTFIX}})
    get_filename_component(TMP_LIBRARY ${${LIB_NAME}_LIBRARY${LIB_POSTFIX}} ABSOLUTE)
  elseif(DEFINED ${LIB_NAME}_LIBRARY${LIB_POSTFIX})
    set(TMP_LIBRARY ${${LIB_NAME}_LIBRARY${LIB_POSTFIX}})
  else()
    set(TMP_LIBRARY "")
  endif()

  set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_LIBRARY})

endmacro()

function(get_library_files_debug OUTPUT)

  add_gtest_library(${OUTPUT} ${GOOGLETEST_MODULE_NAME_UPPER} "_DEBUG")
  add_gtest_library(${OUTPUT} ${GOOGLETEST_MODULE_NAME_UPPER}_MAIN "_DEBUG")

endfunction()

function(get_library_files_release OUTPUT)

  add_gtest_library(${OUTPUT} ${GOOGLETEST_MODULE_NAME_UPPER} "")
  add_gtest_library(${OUTPUT} ${GOOGLETEST_MODULE_NAME_UPPER}_MAIN "")

endfunction()

macro(add_binary_file OUTPUT BINARY_NAME BINARY_POSTFIX)

  if(EXISTS ${${BINARY_NAME}_BINARY${BINARY_POSTFIX}})
    get_filename_component(TMP_BINARY_FILE ${${BINARY_NAME}_BINARY${BINARY_POSTFIX}} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_BINARY_FILE})
  endif()

endmacro()

function(get_binary_files OUTPUT)

  set_parent_scope(${OUTPUT} "")
  add_binary_file(${OUTPUT} ${GOOGLETEST_MODULE_NAME_UPPER} "_DEBUG")
  add_binary_file(${OUTPUT} ${GOOGLETEST_MODULE_NAME_UPPER} "")
  add_binary_file(${OUTPUT} ${GOOGLETEST_MODULE_NAME_UPPER}_MAIN "_DEBUG")
  add_binary_file(${OUTPUT} ${GOOGLETEST_MODULE_NAME_UPPER}_MAIN "")

endfunction()