macro(find_required_library)

  set(FFMPEG_INCLUDE_DIRECTORY "" CACHE PATH "")

  set(FFMPEG_AVCODEC_LIBRARY "" CACHE PATH "")
  set(FFMPEG_AVDEVICE_LIBRARY "" CACHE PATH "")
  set(FFMPEG_AVFILTER_LIBRARY "" CACHE PATH "")
  set(FFMPEG_AVFORMAT_LIBRARY "" CACHE PATH "")
  set(FFMPEG_AVUTIL_LIBRARY "" CACHE PATH "")
  set(FFMPEG_AVPOSTPROC_LIBRARY "" CACHE PATH "")
  set(FFMPEG_SWRESAMPLE_LIBRARY "" CACHE PATH "")
  set(FFMPEG_SWSCALE_LIBRARY "" CACHE PATH "")

  set(FFMPEG_AVCODEC_BINARY "" CACHE PATH "")
  set(FFMPEG_AVDEVICE_BINARY "" CACHE PATH "")
  set(FFMPEG_AVFILTER_BINARY "" CACHE PATH "")
  set(FFMPEG_AVFORMAT_BINARY "" CACHE PATH "")
  set(FFMPEG_AVUTIL_BINARY "" CACHE PATH "")
  set(FFMPEG_POSTPROC_BINARY "" CACHE PATH "")
  set(FFMPEG_SWRESAMPLE_BINARY "" CACHE PATH "")
  set(FFMPEG_SWSCALE_BINARY "" CACHE PATH "")

endmacro()

function(required_library_exists BOOL)

  set(${BOOL} FALSE PARENT_SCOPE)
  if (EXISTS "${FFMPEG_INCLUDE_DIRECTORY}" AND
    EXISTS "${FFMPEG_AVCODEC_LIBRARY}" AND
    EXISTS "${FFMPEG_AVDEVICE_LIBRARY}" AND
    EXISTS "${FFMPEG_AVFILTER_LIBRARY}" AND
    EXISTS "${FFMPEG_AVFORMAT_LIBRARY}" AND
    EXISTS "${FFMPEG_AVUTIL_LIBRARY}" AND
    EXISTS "${FFMPEG_AVPOSTPROC_LIBRARY}" AND
    EXISTS "${FFMPEG_SWRESAMPLE_LIBRARY}" AND
    EXISTS "${FFMPEG_SWSCALE_LIBRARY}")

    set(${BOOL} TRUE PARENT_SCOPE)
  endif()

endfunction()

function(get_include_directories OUTPUT)

  get_filename_component(TMP_INCLUDE_DIRECTORY ${FFMPEG_INCLUDE_DIRECTORY} ABSOLUTE)
  set_parent_scope(${OUTPUT} ${TMP_INCLUDE_DIRECTORY})

endfunction()

function(get_library_files_release OUTPUT)

  get_filename_component(TMP_FFMPEG_AVCODEC_LIBRARY ${FFMPEG_AVCODEC_LIBRARY} ABSOLUTE)
  get_filename_component(TMP_FFMPEG_AVDEVICE_LIBRARY ${FFMPEG_AVDEVICE_LIBRARY} ABSOLUTE)
  get_filename_component(TMP_FFMPEG_AVFILTER_LIBRARY ${FFMPEG_AVFILTER_LIBRARY} ABSOLUTE)
  get_filename_component(TMP_FFMPEG_AVFORMAT_LIBRARY ${FFMPEG_AVFORMAT_LIBRARY} ABSOLUTE)
  get_filename_component(TMP_FFMPEG_AVUTIL_LIBRARY ${FFMPEG_AVUTIL_LIBRARY} ABSOLUTE)
  get_filename_component(TMP_FFMPEG_AVPOSTPROC_LIBRARY ${FFMPEG_AVPOSTPROC_LIBRARY} ABSOLUTE)
  get_filename_component(TMP_FFMPEG_SWRESAMPLE_LIBRARY ${FFMPEG_SWRESAMPLE_LIBRARY} ABSOLUTE)
  get_filename_component(TMP_FFMPEG_SWSCALE_LIBRARY ${FFMPEG_SWSCALE_LIBRARY} ABSOLUTE)

  set_parent_scope(${OUTPUT}
    ${TMP_FFMPEG_AVCODEC_LIBRARY}
    ${TMP_FFMPEG_AVDEVICE_LIBRARY}
    ${TMP_FFMPEG_AVFILTER_LIBRARY}
    ${TMP_FFMPEG_AVFORMAT_LIBRARY}
    ${TMP_FFMPEG_AVUTIL_LIBRARY}
    ${TMP_FFMPEG_AVPOSTPROC_LIBRARY}
    ${TMP_FFMPEG_SWRESAMPLE_LIBRARY}
    ${TMP_FFMPEG_SWSCALE_LIBRARY})

endfunction()

function(get_binary_files OUTPUT)

  set(FFMPEG_BINARY_FILES
    ${FFMPEG_AVCODEC_BINARY}
    ${FFMPEG_AVDEVICE_BINARY}
    ${FFMPEG_AVFILTER_BINARY}
    ${FFMPEG_AVFORMAT_BINARY}
    ${FFMPEG_AVUTIL_BINARY}
    ${FFMPEG_SWRESAMPLE_BINARY}
    ${FFMPEG_SWSCALE_BINARY}
    ${FFMPEG_POSTPROC_BINARY})

  foreach(BIN_FILE IN ITEMS ${FFMPEG_BINARY_FILES})
    get_filename_component(TMP_BIN_FILE ${BIN_FILE} ABSOLUTE)
    set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_BIN_FILE})
  endforeach()

endfunction()