macro(find_required_library)

  set(QT_ROOT_DIRECTORY "" CACHE STRING "")
  if (EXISTS ${QT_ROOT_DIRECTORY})
    get_filename_component(TMP_QT_ROOT_DIRECTORY ${QT_ROOT_DIRECTORY} ABSOLUTE)
    set(CMAKE_PREFIX_PATH ${TMP_QT_ROOT_DIRECTORY})
  endif()

  if (EXISTS ${CMAKE_PREFIX_PATH})
    foreach(MODULE IN ITEMS ${ARGN})
      find_package(Qt6${MODULE})
    endforeach()
  endif()

endmacro()

function(find_required_binaries)


endfunction()

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

  set_parent_scope(${OUTPUT} "")
  foreach(MODULE IN ITEMS ${ARGN})
    foreach(INCLUDE_DIR IN ITEMS ${Qt6${MODULE}_INCLUDE_DIRS})
      get_filename_component(TMP_INCLUDE_DIRECTORY ${INCLUDE_DIR} ABSOLUTE)
      set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_INCLUDE_DIRECTORY})
    endforeach()
  endforeach()

  list(REMOVE_DUPLICATES ${OUTPUT})

endfunction()

function(get_library_files_debug OUTPUT)

  set_parent_scope(${OUTPUT} "")

endfunction()

function(get_library_files_release OUTPUT)

  set_parent_scope(${OUTPUT} "")
  foreach(MODULE IN ITEMS ${ARGN})
    set_parent_scope(${OUTPUT} ${${OUTPUT}} Qt6::${MODULE})
  endforeach()

endfunction()

function(get_binary_files OUTPUT)


endfunction()
