function(osg_amend_libs LIB_TYPE LIB_SUFFIX)

  if (EXISTS ${OSG_LIBRARY_${LIB_TYPE}})
    get_filename_component(LIBRARY_PATH ${OSG_LIBRARY_${LIB_TYPE}} DIRECTORY)
    foreach (MODULE IN ITEMS ${ARGN})
      string(TOUPPER ${MODULE} MODULE_UPPER)
      if (NOT EXISTS ${${MODULE_UPPER}_LIBRARY_${LIB_TYPE}})
        if (EXISTS ${LIBRARY_PATH}/${MODULE}${LIB_SUFFIX}.lib)
          unset(${MODULE_UPPER}_LIBRARY_${LIB_TYPE} CACHE)
          set(${MODULE_UPPER}_LIBRARY_${LIB_TYPE} ${LIBRARY_PATH}/${MODULE}${LIB_SUFFIX}.lib CACHE STRING "")
        endif()
      endif()
    endforeach()
  endif()

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

  osg_amend_libs(RELEASE "" ${ARGV})
  osg_amend_libs(DEBUG "d" ${ARGV})

  foreach (MODULE IN ITEMS ${ARGV})
    string(TOUPPER ${MODULE} MODULE)
    if (NOT EXISTS ${${MODULE}_LIBRARY_DEBUG})
      if (EXISTS ${${MODULE}_LIBRARY_RELEASE})
        unset(${MODULE}_LIBRARY_DEBUG CACHE)
        set(${MODULE}_LIBRARY_DEBUG ${${MODULE}_LIBRARY_RELEASE} CACHE STRING "")
      endif()
    endif()
  endforeach()

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