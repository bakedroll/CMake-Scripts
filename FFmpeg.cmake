macro(find_required_library)

  find_package(FFmpeg COMPONENTS ${ARGN})

  foreach(MODULE IN ITEMS ${ARGN})
    set(${MODULE}_BINARY "" CACHE PATH "")
  endforeach()

endmacro()

function(required_library_exists BOOL)

  set(${BOOL} FALSE PARENT_SCOPE)
  if (EXISTS "${FFMPEG_INCLUDE_DIRS}")
    foreach(MODULE IN ITEMS ${ARGN})
      if (NOT EXISTS "${${MODULE}_LIBRARY}")
        message(STATUS "NOT EXISTING: ${${MODULE}_LIBRARY}")
        return()
      endif()
    endforeach()

    set(${BOOL} TRUE PARENT_SCOPE)
  endif()

endfunction()

function(get_include_directories OUTPUT)

  get_filename_component(TMP_INCLUDE_DIRECTORY ${FFMPEG_INCLUDE_DIRS} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_INCLUDE_DIRECTORY})

endfunction()

function(get_library_files_release OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    get_filename_component(TMP_FFMPEG_MODULE_LIBRARY ${${MODULE}_LIBRARY} ABSOLUTE)
    set(TMP_FFMPEG_LIBRARIES ${TMP_FFMPEG_LIBRARIES} ${TMP_FFMPEG_MODULE_LIBRARY})
  endforeach()

  set_parent_scope(${OUTPUT} "${TMP_FFMPEG_LIBRARIES}")

endfunction()

function(get_binary_files OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    get_filename_component(TMP_FFMPEG_MODULE_BINARY ${${MODULE}_BINARY} ABSOLUTE)
    set(TMP_FFMPEG_BINARIES ${TMP_FFMPEG_BINARIES} ${TMP_FFMPEG_MODULE_BINARY})
  endforeach()

  set_parent_scope(${OUTPUT} "${TMP_FFMPEG_BINARIES}")

endfunction()