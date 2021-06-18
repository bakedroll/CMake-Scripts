macro(find_required_library)

  # Compiler flag for Qt that was built with -reduce-relocations
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

  set(QT_ROOT_DIRECTORY "" CACHE STRING "")
  if (EXISTS ${QT_ROOT_DIRECTORY})
    get_filename_component(TMP_QT_ROOT_DIRECTORY ${QT_ROOT_DIRECTORY} ABSOLUTE)
    set(CMAKE_PREFIX_PATH ${TMP_QT_ROOT_DIRECTORY})
  endif()

  foreach(MODULE IN ITEMS ${ARGN})
    find_package(Qt6${MODULE})
  endforeach()

endmacro()

function(required_library_exists BOOL)

  set(${BOOL} TRUE PARENT_SCOPE)
  foreach(MODULE IN ITEMS ${ARGN})
    if (NOT DEFINED Qt6${MODULE}_LIBRARIES)
      set(${BOOL} FALSE PARENT_SCOPE)
      return()
    endif()

    if (NOT DEFINED Qt6${MODULE}_INCLUDE_DIRS)
      set(${BOOL} FALSE PARENT_SCOPE)
      return()
    endif()

    foreach(INCLUDE_DIR IN ITEMS ${Qt6${MODULE}_INCLUDE_DIRS})
      if (NOT EXISTS ${INCLUDE_DIR})
        set(${BOOL} FALSE PARENT_SCOPE)
        return()
      endif()
    endforeach()
  endforeach()

endfunction()

function(get_include_directories OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    foreach(INCLUDE_DIR IN ITEMS ${Qt6${MODULE}_INCLUDE_DIRS})
      get_filename_component(TMP_INCLUDE_DIRECTORY ${INCLUDE_DIR} ABSOLUTE)
      set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_INCLUDE_DIRECTORY})
    endforeach()
  endforeach()

  list(REMOVE_DUPLICATES ${OUTPUT})

endfunction()

function(get_library_files_release OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    set_parent_scope(${OUTPUT} ${${OUTPUT}} Qt6::${MODULE})
  endforeach()

endfunction()

function(get_binary_files OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    get_filename_component(TMP_BIN_RELEASE ${QT_ROOT_DIRECTORY}/bin/Qt6${MODULE}.dll ABSOLUTE)
    if (EXISTS ${TMP_BIN_RELEASE})
      set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_BIN_RELEASE})
    endif()
    get_filename_component(TMP_BIN_DEBUG ${QT_ROOT_DIRECTORY}/bin/Qt6${MODULE}d.dll ABSOLUTE)
    if (EXISTS ${TMP_BIN_DEBUG})
      set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_BIN_DEBUG})
    endif()
  endforeach()

endfunction()

macro(copy_file_configuration FILE_DIRECTORY FILE_NAME CONFIG_POSTFIX)

  if (EXISTS ${FILE_DIRECTORY}/${FILE_NAME}${CONFIG_POSTFIX}.dll)
    configure_file(
      ${FILE_DIRECTORY}/${FILE_NAME}${CONFIG_POSTFIX}.dll
      ${CMAKE_BINARY_DIR}/${PROJECT_BIN_DIR}/${FILE_NAME}${CONFIG_POSTFIX}.dll COPYONLY)
  else()
    message(WARNING "Could not copy additional Qt6 binary ${FILE_NAME}${CONFIG_POSTFIX}.dll")
  endif()

endmacro()

function(qt6_copy_plugins)

  if (NOT EXISTS ${QT_ROOT_DIRECTORY})
    return()
  endif()

  message(STATUS "Copying Qt6 plugin binaries")

  get_filename_component(TMP_QT_ROOT_DIRECTORY ${QT_ROOT_DIRECTORY} ABSOLUTE)

  foreach(PLUGIN IN ITEMS ${ARGN})
    copy_file_configuration(${TMP_QT_ROOT_DIRECTORY}/plugins ${PLUGIN} "")
    copy_file_configuration(${TMP_QT_ROOT_DIRECTORY}/plugins ${PLUGIN} "d")
  endforeach()

endfunction()