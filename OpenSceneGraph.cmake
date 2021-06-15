function(osg_amend_files FILE_TYPE FILE_CONFIG FILE_SUFFIX FILE_EXTENSION)

  if (EXISTS ${OSG_${FILE_TYPE}_${FILE_CONFIG}})
    get_filename_component(FILE_PATH ${OSG_${FILE_TYPE}_${FILE_CONFIG}} DIRECTORY)
    foreach (MODULE IN ITEMS ${ARGN})
      string(TOUPPER ${MODULE} MODULE_UPPER)
      if (NOT EXISTS ${${MODULE_UPPER}_${FILE_TYPE}_${FILE_CONFIG}})
        if (EXISTS ${FILE_PATH}/${MODULE}${FILE_SUFFIX}.${FILE_EXTENSION})
          unset(${MODULE_UPPER}_${FILE_TYPE}_${FILE_CONFIG} CACHE)
          set(${MODULE_UPPER}_${FILE_TYPE}_${FILE_CONFIG} ${FILE_PATH}/${MODULE}${FILE_SUFFIX}.${FILE_EXTENSION} CACHE STRING "")
        endif()
      endif()
    endforeach()
  endif()

endfunction()

function(osg_fill_debug_files FILE_TYPE)

  foreach (MODULE IN ITEMS ${ARGN})
    string(TOUPPER ${MODULE} MODULE)
    if (NOT EXISTS ${${MODULE}_${FILE_TYPE}_DEBUG})
      if (EXISTS ${${MODULE}_${FILE_TYPE}_RELEASE})
        unset(${MODULE}_${FILE_TYPE}_DEBUG CACHE)
        set(${MODULE}_${FILE_TYPE}_DEBUG ${${MODULE}_${FILE_TYPE}_RELEASE} CACHE STRING "")
      endif()
    endif()
  endforeach()

endfunction()

function(find_required_library)

  find_package(OpenSceneGraph COMPONENTS ${ARGV})

  if (EXISTS ${OSG_INCLUDE_DIR})
    foreach (MODULE IN ITEMS ${ARGV})
      string(TOUPPER ${MODULE} MODULE)
      if (NOT EXISTS ${${MODULE}_INCLUDE_DIR})
        unset(${MODULE}_INCLUDE_DIR CACHE)
        set(${MODULE}_INCLUDE_DIR ${OSG_INCLUDE_DIR} CACHE STRING "")
      endif()
    endforeach()
  endif()

  osg_amend_files(LIBRARY RELEASE "" "lib" ${ARGV})
  osg_amend_files(LIBRARY DEBUG "d" "lib" ${ARGV})

  osg_fill_debug_files(LIBRARY ${ARGV})

  if(NOT DEFINED OSG_PLUGINS_DIRECTORY)
    set(OSG_PLUGINS_DIRECTORY "" CACHE STRING "")
  endif()

endfunction()

function(find_required_binaries)

  foreach(MODULE IN ITEMS ${ARGN})

    string(TOUPPER ${MODULE} MODULE_UPPER)
    if(NOT DEFINED ${MODULE_UPPER}_BINARY_RELEASE)
      set(${MODULE_UPPER}_BINARY_RELEASE "" CACHE STRING "")
    endif()
    if(NOT DEFINED ${MODULE_UPPER}_BINARY_DEBUG)
      set(${MODULE_UPPER}_BINARY_DEBUG "" CACHE STRING "")
    endif()

  endforeach()

  osg_amend_files(BINARY RELEASE "" "dll" ${ARGN})
  osg_amend_files(BINARY DEBUG "d" "dll" ${ARGN})

  osg_fill_debug_files(BINARY ${ARGN})

endfunction()

function(required_library_exists BOOL)

  set(${BOOL} TRUE PARENT_SCOPE)

  if (NOT "${ARGN}")
    if (NOT EXISTS ${OSG_INCLUDE_DIR})
      set(${BOOL} FALSE PARENT_SCOPE)
    endif()
  else()
    foreach (MODULE IN ITEMS ${ARGN})
      string(TOUPPER ${MODULE} MODULE)
      if (NOT EXISTS ${${MODULE}_LIBRARY_DEBUG})
        set(${BOOL} FALSE PARENT_SCOPE)
      endif()
      if (NOT EXISTS ${${MODULE}_LIBRARY_RELEASE})
        set(${BOOL} FALSE PARENT_SCOPE)
      endif()
      if (NOT EXISTS ${${MODULE}_INCLUDE_DIR})
        set(${BOOL} FALSE PARENT_SCOPE)
      endif()
    endforeach()
  endif()

endfunction()

function(get_include_directories OUTPUT)

  if (NOT "${ARGN}")
    get_filename_component(TMP_INCLUDE_DIRECTORY ${OSG_INCLUDE_DIR} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${TMP_INCLUDE_DIRECTORY})
  else()
    set_parent_scope(${OUTPUT} "")
    foreach(MODULE IN ITEMS ${ARGN})
      string(TOUPPER ${MODULE} MODULE)
      get_filename_component(TMP_INCLUDE_DIRECTORY ${${MODULE}_INCLUDE_DIR} ABSOLUTE)
      set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_INCLUDE_DIRECTORY})
    endforeach()
  endif()

  list(REMOVE_DUPLICATES ${OUTPUT})

endfunction()

macro(get_library_files_conf OUTPUT CONFIG)

  set_parent_scope(${OUTPUT} "")
  foreach(MODULE IN ITEMS ${ARGN})
    string(TOUPPER ${MODULE} MODULE)
    get_filename_component(TMP_LIBRARY_${CONFIG} ${${MODULE}_LIBRARY_${CONFIG}} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_LIBRARY_${CONFIG}})
  endforeach()

endmacro()

function(get_library_files_debug OUTPUT)

  get_library_files_conf(${OUTPUT} DEBUG ${ARGN})

endfunction()

function(get_library_files_release OUTPUT)

  get_library_files_conf(${OUTPUT} RELEASE ${ARGN})

endfunction()

function(get_binary_files OUTPUT)

  set_parent_scope(${OUTPUT} "")
  foreach(MODULE IN ITEMS ${ARGN})

    string(TOUPPER ${MODULE} MODULE_UPPER)
    if(EXISTS ${${MODULE_UPPER}_BINARY_RELEASE})
      get_filename_component(TMP_BINARY_FILE ${${MODULE_UPPER}_BINARY_RELEASE} ABSOLUTE)
      set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_BINARY_FILE})
    endif()
    if(EXISTS ${${MODULE_UPPER}_BINARY_DEBUG})
      get_filename_component(TMP_BINARY_FILE ${${MODULE_UPPER}_BINARY_DEBUG} ABSOLUTE)
      set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_BINARY_FILE})
    endif()

  endforeach()

endfunction()

macro(copy_file_configuration FILE_DIRECTORY FILE_NAME CONFIG_POSTFIX)

  if (EXISTS ${FILE_DIRECTORY}/${FILE_NAME}${CONFIG_POSTFIX}.dll)
    configure_file(
      ${FILE_DIRECTORY}/${FILE_NAME}${CONFIG_POSTFIX}.dll
      ${CMAKE_BINARY_DIR}/${PROJECT_BIN_DIR}/${FILE_NAME}${CONFIG_POSTFIX}.dll COPYONLY)
  else()
    message(WARNING "Could not copy additional OpenSceneGraph binary ${FILE_NAME}${CONFIG_POSTFIX}.dll")
  endif()

endmacro()

function(osg_copy_additional_binaries)

  get_filename_component(BINARIES_DIRECTORY ${OSG_BINARY_RELEASE} DIRECTORY)
  if (EXISTS ${BINARIES_DIRECTORY})
    message(STATUS "Copying additional OpenSceneGraph binaries")
    foreach (BINARY_NAME IN ITEMS ${ARGN})
      copy_file_configuration(${BINARIES_DIRECTORY} ${BINARY_NAME} "")
      copy_file_configuration(${BINARIES_DIRECTORY} ${BINARY_NAME} "d")
    endforeach()
  endif()

endfunction()

function(osg_copy_plugins)

  if (EXISTS ${OSG_PLUGINS_DIRECTORY})
    get_filename_component(TMP_OSG_PLUGINS_DIRECTORY ${OSG_PLUGINS_DIRECTORY} ABSOLUTE)

    message(STATUS "Copying OpenSceneGraph plugin binaries")
    foreach (BINARY_NAME IN ITEMS ${ARGN})
      copy_file_configuration(${TMP_OSG_PLUGINS_DIRECTORY} ${BINARY_NAME} "")
      copy_file_configuration(${TMP_OSG_PLUGINS_DIRECTORY} ${BINARY_NAME} "d")
    endforeach()
  else()
    message(WARNING "OSG_PLUGINS_DIRECTORY is undefined")
  endif()

endfunction()