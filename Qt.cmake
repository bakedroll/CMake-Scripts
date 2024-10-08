if (NOT DEFINED QT_REQUIRED_VERSION)
  if (QT_USE_VERSION_5)
    set(QT_REQUIRED_VERSION "5")
  else()
    set(QT_REQUIRED_VERSION "6")
  endif()
endif()

macro(find_required_library)

  # Compiler flag for Qt that was built with -reduce-relocations
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

  set(QT_ROOT_DIRECTORY "" CACHE STRING "")
  if (EXISTS ${QT_ROOT_DIRECTORY})
    get_filename_component(TMP_QT_ROOT_DIRECTORY ${QT_ROOT_DIRECTORY} ABSOLUTE)
    set(CMAKE_PREFIX_PATH ${TMP_QT_ROOT_DIRECTORY})
  endif()

  if (${QT_REQUIRED_VERSION} STREQUAL "6")
    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

    if (MSVC)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zc:__cplusplus /permissive-")
    endif()
  endif()

  foreach(MODULE IN ITEMS ${ARGN})
    if (${QT_REQUIRED_VERSION} STREQUAL "5" AND ${MODULE} STREQUAL "OpenGLWidgets")
      continue()
    endif()
    find_package(Qt${QT_REQUIRED_VERSION}${MODULE})
  endforeach()

endmacro()

function(required_library_exists BOOL)

  set(${BOOL} TRUE PARENT_SCOPE)
  foreach(MODULE IN ITEMS ${ARGN})
    if (${QT_REQUIRED_VERSION} STREQUAL "5" AND ${MODULE} STREQUAL "OpenGLWidgets")
      continue()
    endif()

    if (NOT DEFINED Qt${QT_REQUIRED_VERSION}${MODULE}_LIBRARIES)
      set(${BOOL} FALSE PARENT_SCOPE)
      return()
    endif()

    if (NOT DEFINED Qt${QT_REQUIRED_VERSION}${MODULE}_INCLUDE_DIRS)
      set(${BOOL} FALSE PARENT_SCOPE)
      return()
    endif()
  endforeach()

endfunction()

function(get_include_directories OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    if (${QT_REQUIRED_VERSION} STREQUAL "5" AND ${MODULE} STREQUAL "OpenGLWidgets")
      continue()
    endif()

    foreach(INCLUDE_DIR IN ITEMS ${Qt${QT_REQUIRED_VERSION}${MODULE}_INCLUDE_DIRS})
      get_filename_component(TMP_INCLUDE_DIRECTORY ${INCLUDE_DIR} ABSOLUTE)
      set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_INCLUDE_DIRECTORY})
    endforeach()
  endforeach()

  list(REMOVE_DUPLICATES ${OUTPUT})

endfunction()

function(get_library_files_release OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    if (${QT_REQUIRED_VERSION} STREQUAL "5" AND ${MODULE} STREQUAL "OpenGLWidgets")
      continue()
    endif()

    set_parent_scope(${OUTPUT} ${${OUTPUT}} Qt${QT_REQUIRED_VERSION}::${MODULE})
  endforeach()

endfunction()

function(get_binary_files OUTPUT)

  foreach(MODULE IN ITEMS ${ARGN})
    if (${QT_REQUIRED_VERSION} STREQUAL "5" AND ${MODULE} STREQUAL "OpenGLWidgets")
      continue()
    endif()

    get_filename_component(TMP_BIN_RELEASE ${QT_ROOT_DIRECTORY}/bin/Qt${QT_REQUIRED_VERSION}${MODULE}.dll ABSOLUTE)
    if (EXISTS ${TMP_BIN_RELEASE})
      set_parent_scope(${OUTPUT} ${${OUTPUT}} ${TMP_BIN_RELEASE})
    endif()
    get_filename_component(TMP_BIN_DEBUG ${QT_ROOT_DIRECTORY}/bin/Qt${QT_REQUIRED_VERSION}${MODULE}d.dll ABSOLUTE)
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
    message(WARNING "Could not copy additional Qt binary ${FILE_NAME}${CONFIG_POSTFIX}.dll")
  endif()

endmacro()

function(qt_copy_plugins)

  if (NOT EXISTS ${QT_ROOT_DIRECTORY})
    return()
  endif()

  message(STATUS "Copying Qt plugin binaries")

  get_filename_component(TMP_QT_ROOT_DIRECTORY ${QT_ROOT_DIRECTORY} ABSOLUTE)

  foreach(PLUGIN IN ITEMS ${ARGN})
    copy_file_configuration(${TMP_QT_ROOT_DIRECTORY}/plugins ${PLUGIN} "")
    copy_file_configuration(${TMP_QT_ROOT_DIRECTORY}/plugins ${PLUGIN} "d")
  endforeach()

endfunction()

function(qt_copy_qml_binaries)

  if (NOT EXISTS ${QT_ROOT_DIRECTORY})
    return()
  endif()

  message(STATUS "Copying Qt qml binaries")

  get_filename_component(TMP_QT_ROOT_DIRECTORY ${QT_ROOT_DIRECTORY} ABSOLUTE)

  foreach(BINARY IN ITEMS ${ARGN})
    copy_file_configuration(${TMP_QT_ROOT_DIRECTORY} qml/${BINARY} "")
    copy_file_configuration(${TMP_QT_ROOT_DIRECTORY} qml/${BINARY} "d")

    get_filename_component(CURRENT_QML_DIR ${BINARY} DIRECTORY)

    if (EXISTS ${TMP_QT_ROOT_DIRECTORY}/qml/${CURRENT_QML_DIR}/plugins.qmltypes)
      configure_file(
        ${TMP_QT_ROOT_DIRECTORY}/qml/${CURRENT_QML_DIR}/plugins.qmltypes
        ${CMAKE_BINARY_DIR}/${PROJECT_BIN_DIR}/qml/${CURRENT_QML_DIR}/plugins.qmltypes COPYONLY)
    endif()
    if (EXISTS ${TMP_QT_ROOT_DIRECTORY}/qml/${CURRENT_QML_DIR}/qmldir)
      configure_file(
        ${TMP_QT_ROOT_DIRECTORY}/qml/${CURRENT_QML_DIR}/qmldir
        ${CMAKE_BINARY_DIR}/${PROJECT_BIN_DIR}/qml/${CURRENT_QML_DIR}/qmldir COPYONLY)

        file(GLOB QML_FILES ${TMP_QT_ROOT_DIRECTORY}/qml/${CURRENT_QML_DIR}/*.qml)
        foreach (QML_FILE_PATH IN ITEMS ${QML_FILES})
          get_filename_component(QML_FILE ${QML_FILE_PATH} NAME)
          configure_file(
            ${TMP_QT_ROOT_DIRECTORY}/qml/${CURRENT_QML_DIR}/${QML_FILE}
            ${CMAKE_BINARY_DIR}/${PROJECT_BIN_DIR}/qml/${CURRENT_QML_DIR}/${QML_FILE} COPYONLY)
        endforeach()
    endif()
  endforeach()

endfunction()

function(qt_copy_additional_binaries)

  if (NOT EXISTS ${QT_ROOT_DIRECTORY})
    return()
  endif()

  message(STATUS "Copying additional Qt binaries")

  get_filename_component(TMP_QT_ROOT_DIRECTORY ${QT_ROOT_DIRECTORY} ABSOLUTE)

  foreach(BINARY IN ITEMS ${ARGN})
    copy_file_configuration(${TMP_QT_ROOT_DIRECTORY}/bin ${BINARY} "")
    copy_file_configuration(${TMP_QT_ROOT_DIRECTORY}/bin ${BINARY} "d")
  endforeach()

endfunction()
