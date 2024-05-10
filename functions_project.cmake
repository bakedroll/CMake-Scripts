if (WIN32)
  set(LUPDATE_PATH ${QT_ROOT_DIRECTORY}/bin/lupdate)
else()
  set(LUPDATE_PATH lupdate)
endif()

macro(set_parent_scope VAR)

  set(${VAR} ${ARGN})
  list(REMOVE_DUPLICATES ${VAR})
  set(${VAR} ${${VAR}} PARENT_SCOPE)

endmacro()

macro(parse_args_require_library ARG_TYPE)

  if (${ARG_TYPE} STREQUAL "MODULES")
    set(LIBRARY_MODULES ${ARGN})
  endif()

endmacro()

macro(begin_project PROJECT_NAME PROJECT_TYPE)

  set(CURRENT_PROJECT_NAME ${PROJECT_NAME})

  if (${PROJECT_TYPE} STREQUAL "LIBRARY")
    set_parent_scope(PROJECTS_LIBRARY ${PROJECTS_LIBRARY} ${PROJECT_NAME})
  elseif(${PROJECT_TYPE} STREQUAL "EXECUTABLE")
    set_parent_scope(PROJECTS_EXECUTABLE ${PROJECTS_EXECUTABLE} ${PROJECT_NAME})
  elseif(${PROJECT_TYPE} STREQUAL "INTERFACE")
    set_parent_scope(PROJECTS_INTERFACE ${PROJECTS_INTERFACE} ${PROJECT_NAME})
  else()
    message(FATAL_ERROR "Unexpected argument at begin_project")
  endif()

  if ("${ARGN}" STREQUAL "OPTIONAL")
    set_parent_scope(PROJECT_${PROJECT_NAME}_OPTIONAL TRUE)
  endif()

  set_parent_scope(PROJECT_${PROJECT_NAME}_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

endmacro()

macro(require_library LIBRARY_NAME)

  set(LIBRARY_MODULES "")
  if (${ARGC} GREATER 1)
    parse_args_require_library(${ARGN})
  endif()

  set_parent_scope(REQUIRED_LIBRARIES ${REQUIRED_LIBRARIES} ${LIBRARY_NAME})
  set_parent_scope(LIBRARY_${LIBRARY_NAME}_MODULES ${LIBRARY_${LIBRARY_NAME}_MODULES} ${LIBRARY_MODULES})

  set_parent_scope(
    PROJECT_${CURRENT_PROJECT_NAME}_REQUIRED_LIBRARIES
    ${PROJECT_${CURRENT_PROJECT_NAME}_REQUIRED_LIBRARIES} ${LIBRARY_NAME})

  set_parent_scope(
    PROJECT_${CURRENT_PROJECT_NAME}_LIBRARY_${LIBRARY_NAME}_MODULES
    ${PROJECT_${CURRENT_PROJECT_NAME}_LIBRARY_${LIBRARY_NAME}_MODULES} ${LIBRARY_MODULES})

endmacro()

macro(parse_args_require_project ARG_TYPE)

  if (${ARG_TYPE} STREQUAL "PATH")
    set(REQUIRED_PROJECT_PATH ${ARGN})
  endif()

endmacro()

function(add_project PROJECT_NAME)

  add_required_project(${PROJECT_NAME} ${ARGN})

endfunction()

macro(add_required_project PROJECT_NAME)

  set(REQUIRED_PROJECT_PATH "")
  if (${ARGC} GREATER 1)
    parse_args_require_project(${ARGN})
  endif()

  set_parent_scope(REQUIRED_PROJECTS ${REQUIRED_PROJECTS} ${PROJECT_NAME})
  set_parent_scope(REQUIRED_PROJECT_${PROJECT_NAME}_PATH ${REQUIRED_PROJECT_PATH})

endmacro()

macro(add_project_definitions)

  set_parent_scope(
    PROJECT_${CURRENT_PROJECT_NAME}_DEFINITIONS
    ${PROJECT_${CURRENT_PROJECT_NAME}_DEFINITIONS} ${ARGN})

endmacro()

macro(require_project PROJECT_NAME)

  add_required_project(${PROJECT_NAME} ${ARGN})

  set_parent_scope(
    PROJECT_${CURRENT_PROJECT_NAME}_REQUIRED_PROJECTS
    ${PROJECT_${CURRENT_PROJECT_NAME}_REQUIRED_PROJECTS} ${PROJECT_NAME})

endmacro()

macro(enable_automoc)

  set_parent_scope(PROJECT_${CURRENT_PROJECT_NAME}_AUTOMOC ON)

endmacro()

macro(enable_autorcc)

  set_parent_scope(PROJECT_${CURRENT_PROJECT_NAME}_AUTORCC ON)

endmacro()

macro(enable_autouic)

  set_parent_scope(PROJECT_${CURRENT_PROJECT_NAME}_AUTOUIC ON)

endmacro()

macro(enable_localized_languages)

  set_parent_scope(PROJECT_${CURRENT_PROJECT_NAME}_LOCALIZED_LANGUAGES ${ARGV})

endmacro()

macro(set_ts_files_directory ARG_DIRECTORY)

  set_parent_scope(PROJECT_${CURRENT_PROJECT_NAME}_TS_FILES_DIRECTORY ${ARG_DIRECTORY})

endmacro()

macro(find_required_projects)

  get_filename_component(CMAKE_SCRIPTS_PARENT_DIR ${CMAKE_SCRIPTS_DIRECTORY} DIRECTORY)
  set(PROJECTS_DIRECTORY ${CMAKE_SCRIPTS_PARENT_DIR} CACHE STRING "The directory where external projects are located")

  set(PROJECTS_TO_ADD "")
  set(PROJECTS_REGISTERED ${ARGN})

  set(REQUIRED_PROJECTS_WO_FAILED ${REQUIRED_PROJECTS})
  list(REMOVE_ITEM REQUIRED_PROJECTS_WO_FAILED ${PROJECTS_FAILED_TO_ADD})

  foreach(PROJECT_REQ_NAME IN ITEMS ${REQUIRED_PROJECTS_WO_FAILED})

    list(FIND PROJECTS_REGISTERED ${PROJECT_REQ_NAME} PROJECT_REQ_INDEX)

    if (${PROJECT_REQ_INDEX} LESS 0)

      # make required project optional if needed
      set(MAKE_OPTIONAL "TRUE")
      foreach(PROJECT_NAME IN ITEMS ${PROJECTS_REGISTERED})
        if (DEFINED PROJECT_${PROJECT_NAME}_REQUIRED_PROJECTS)
          list(FIND PROJECT_${PROJECT_NAME}_REQUIRED_PROJECTS ${PROJECT_REQ_NAME} PROJECT_REQ_INDEX_2)
          if (${PROJECT_REQ_INDEX} GREATER_EQUAL 0)
            if (NOT DEFINED PROJECT_${PROJECT_NAME}_OPTIONAL)
              set(MAKE_OPTIONAL "FALSE")
            endif()
          endif()
        endif()
      endforeach()

      if (${MAKE_OPTIONAL} STREQUAL "TRUE")
        set(PROJECT_${PROJECT_REQ_NAME}_OPTIONAL "TRUE")
      endif()
      ###

      set(PROJECTS_TO_ADD ${PROJECTS_TO_ADD} ${PROJECT_REQ_NAME})
    endif()

  endforeach()

  set(PROJECTS_CHANGED "FALSE")
  foreach(PROJECT_TO_ADD IN ITEMS ${PROJECTS_TO_ADD})

    if (EXISTS ${PROJECTS_DIRECTORY}/${REQUIRED_PROJECT_${PROJECT_TO_ADD}_PATH}/${PROJECT_TO_ADD}/CMakeLists.txt)
      set(PROJECTS_CHANGED "TRUE")
      add_subdirectory(${PROJECTS_DIRECTORY}/${REQUIRED_PROJECT_${PROJECT_TO_ADD}_PATH}/${PROJECT_TO_ADD} ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_TO_ADD})
    else()
      message(WARNING
        "Could not find required project ${PROJECT_REQ_NAME}. Please make sure that PROJECTS_DIRECTORY is defined and contains the relevant projects.")
    endif()

    set(ALL_PROJECTS ${PROJECTS_LIBRARY} ${PROJECTS_EXECUTABLE} ${PROJECTS_INTERFACE})
    list(FIND ALL_PROJECTS ${PROJECT_TO_ADD} PROJECT_ADDED_INDEX)
    if (${PROJECT_ADDED_INDEX} LESS 0)
      set(PROJECTS_FAILED_TO_ADD ${PROJECTS_FAILED_TO_ADD} ${PROJECT_TO_ADD})
    endif()

  endforeach()

endmacro()

macro(find_dependencies)

  foreach (LIBRARY_NAME IN ITEMS ${REQUIRED_LIBRARIES})

    macro(find_required_library)
      find_package(${LIBRARY_NAME} COMPONENTS ${ARGV})
    endmacro()
    macro(find_required_binaries)
    endmacro()

    if (EXISTS ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
      include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
    endif()

    find_required_library(${LIBRARY_${LIBRARY_NAME}_MODULES})

    if (MSVC)
      find_required_binaries(${LIBRARY_${LIBRARY_NAME}_MODULES})
    endif()

  endforeach()

endmacro()

function(check_dependencies)

  foreach(PROJECT_NAME IN ITEMS ${ARGV})

    # Check internal project dependencies
    foreach(PROJECT_REQ_NAME IN ITEMS ${PROJECT_${PROJECT_NAME}_REQUIRED_PROJECTS})
      list(FIND ARGV ${PROJECT_REQ_NAME} PROJECT_REQ_INDEX)
      if (${PROJECT_REQ_INDEX} LESS 0)

        if ("${PROJECT_${PROJECT_NAME}_OPTIONAL}" STREQUAL "TRUE")
          set(PROJECTS_MISSING_OPTIONAL ${PROJECTS_MISSING_OPTIONAL} ${PROJECT_REQ_NAME})
          set_parent_scope(EXCLUDED_PROJECTS ${EXCLUDED_PROJECTS} ${PROJECT_NAME})
        else()
          set(PROJECTS_MISSING ${PROJECTS_MISSING} ${PROJECT_REQ_NAME})
        endif()

      endif()
    endforeach()

    # Check library dependencies
    foreach(LIBRARY_NAME IN ITEMS ${PROJECT_${PROJECT_NAME}_REQUIRED_LIBRARIES})

      function(required_library_exists BOOL)
        set(${BOOL} UNDEFINED PARENT_SCOPE)
      endfunction()

      if (EXISTS ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
        include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
      endif()

      required_library_exists(BOOL ${PROJECT_${PROJECT_NAME}_LIBRARY_${LIBRARY_NAME}_MODULES})

      if (${BOOL} STREQUAL "FALSE")
        if ("${PROJECT_${PROJECT_NAME}_OPTIONAL}" STREQUAL "TRUE")
          set(LIBRARIES_MISSING_OPTIONAL ${LIBRARIES_MISSING_OPTIONAL} ${LIBRARY_NAME})
          set_parent_scope(EXCLUDED_PROJECTS ${EXCLUDED_PROJECTS} ${PROJECT_NAME})
        else()
          set(LIBRARIES_MISSING ${LIBRARIES_MISSING} ${LIBRARY_NAME})
        endif()
      endif()

    endforeach()

  endforeach()

  list(REMOVE_DUPLICATES LIBRARIES_MISSING)
  list(REMOVE_DUPLICATES LIBRARIES_MISSING_OPTIONAL)
  list(REMOVE_DUPLICATES PROJECTS_MISSING)
  list(REMOVE_DUPLICATES PROJECTS_MISSING_OPTIONAL)
  list(REMOVE_DUPLICATES EXCLUDED_PROJECTS)

  list(REMOVE_ITEM LIBRARIES_MISSING_OPTIONAL ${LIBRARIES_MISSING})
  list(REMOVE_ITEM PROJECTS_MISSING_OPTIONAL ${PROJECTS_MISSING})

  foreach (LIB IN ITEMS ${LIBRARIES_MISSING})
    message(SEND_ERROR "Required dependency ${LIB} missing or incomplete")
  endforeach()

  foreach (PROJ IN ITEMS ${PROJECTS_MISSING})
    message(SEND_ERROR "Required project ${PROJ} missing")
  endforeach()

  foreach (LIB IN ITEMS ${LIBRARIES_MISSING_OPTIONAL})
    message(WARNING "Optional dependency ${LIB} missing or incomplete")
  endforeach()

  foreach (PROJ IN ITEMS ${PROJECTS_MISSING_OPTIONAL})
    message(WARNING "Optional project ${PROJ} missing")
  endforeach()

  foreach (PROJECT_NAME IN ITEMS ${EXCLUDED_PROJECTS})
    message(WARNING "Optional project ${PROJECT_NAME} will be skipped")
  endforeach()

  if (DEFINED LIBRARIES_MISSING)
    message(FATAL_ERROR "One or more required dependencies are not satisfied")
  endif()

endfunction()

macro(make_projects_type PROJECTS PROJECT_TYPE)

  foreach (PROJECT_NAME IN ITEMS ${PROJECTS})
    unset(GENERATED_QM_FILES)

    list(FIND EXCLUDED_PROJECTS ${PROJECT_NAME} EXCLUDED_PROJECT_INDEX)
    if (${EXCLUDED_PROJECT_INDEX} LESS 0)

      set(SOURCE_FILES "")
      foreach (SOURCE_DIR IN ITEMS ${PROJECT_${PROJECT_NAME}_SOURCE_DIRECTORIES})
        set(SOURCE_FILES ${SOURCE_FILES} ${PROJECT_${PROJECT_NAME}_SOURCE_DIR_${SOURCE_DIR}})
      endforeach()

      foreach (QRC_FILE IN ITEMS ${PROJECT_${PROJECT_NAME}_QRC_FILES})
        set(SOURCE_FILES ${SOURCE_FILES} ${QRC_FILE})
      endforeach()

      foreach (TS_FILE IN ITEMS ${PROJECT_${PROJECT_NAME}_TS_FILES})
        if (DEFINED PROJECT_${PROJECT_NAME}_QM_DIRECTORY)
          set_source_files_properties(${TS_FILE} PROPERTIES OUTPUT_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_${PROJECT_NAME}_QM_DIRECTORY}")
        endif()

        qt5_add_translation(GENERATED_QM_FILES ${TS_FILE})
        set(SOURCE_FILES ${SOURCE_FILES} ${TS_FILE})
      endforeach()

      set(QRC_GENERATED_QM_FILES "")
      foreach (QM_FILE IN ITEMS ${GENERATED_QM_FILES})
        get_filename_component(QM_FILE_NAME ${QM_FILE} NAME)
        set(QRC_GENERATED_QM_FILES "${QRC_GENERATED_QM_FILES}<file>${QM_FILE_NAME}</file>")
      endforeach()

      if (QRC_GENERATED_QM_FILES)
        set(TRANSLATIONS_QRC "${CMAKE_BINARY_DIR}/${PROJECT_${PROJECT_NAME}_QM_DIRECTORY}/translations.qrc")
        configure_file("${CMAKE_SCRIPTS_DIRECTORY}/templates/translations.qrc.template" "${TRANSLATIONS_QRC}")
        source_group(GeneratedFiles FILES ${TRANSLATIONS_QRC})
        set(SOURCE_FILES ${SOURCE_FILES} ${TRANSLATIONS_QRC})
      endif()

      source_group(GeneratedFiles FILES ${GENERATED_QM_FILES})
      set(SOURCE_FILES ${SOURCE_FILES} ${GENERATED_QM_FILES})

      message(STATUS "Generating project ${PROJECT_NAME}")

      if (DEFINED PROJECT_${PROJECT_NAME}_AUTOMOC)
        set(CMAKE_AUTOMOC ON)
      endif()
      if (DEFINED PROJECT_${PROJECT_NAME}_AUTORCC)
        set(CMAKE_AUTORCC ON)
      endif()
      if (DEFINED PROJECT_${PROJECT_NAME}_AUTOUIC)
        set(CMAKE_AUTOUIC ON)
      endif()

      unset(QM_FILES)
      unset(TS_FILES_NEW)
      unset(TS_FILES_OLD)

      if (DEFINED PROJECT_${PROJECT_NAME}_LOCALIZED_LANGUAGES)

        unset(TRANSLATED_DIRECTORIES)
        foreach (TRANSLATED_DIR IN ITEMS ${PROJECT_${PROJECT_NAME}_TRANSLATED_DIRECTORIES})
          set(TRANSLATED_DIRECTORIES ${TRANSLATED_DIRECTORIES} ${PROJECT_${PROJECT_NAME}_SOURCE_DIR}/${TRANSLATED_DIR})
        endforeach()

        set(TS_FILES_DIRECTORY ${PROJECT_${PROJECT_NAME}_SOURCE_DIR}/${PROJECT_${PROJECT_NAME}_TS_FILES_DIRECTORY})

        foreach (LANGUAGE IN ITEMS ${PROJECT_${PROJECT_NAME}_LOCALIZED_LANGUAGES})
          set(TS_FILE_PATH ${TS_FILES_DIRECTORY}/${PROJECT_NAME}_${LANGUAGE}.ts)
          if (EXISTS ${TS_FILE_PATH})
            set(TS_FILES_OLD ${TS_FILES_OLD} ${TS_FILE_PATH})
          else()
            set(TS_FILES_NEW ${TS_FILES_NEW} ${TS_FILE_PATH})
          endif()
        endforeach()

        if (DEFINED TS_FILES_NEW)
          qt_create_translation(QM_FILES ${TRANSLATED_DIRECTORIES} ${TS_FILES_NEW})
        endif()

        foreach (TS_FILE_NAME IN ITEMS ${TS_FILES_OLD} ${TS_FILES_NEW})
          get_filename_component(TS_FILE_PATH ${TS_FILE_NAME} DIRECTORY)
          set_source_files_properties(${TS_FILE_NAME} PROPERTIES OUTPUT_LOCATION ${TS_FILE_PATH})
        endforeach()

        unset(QM_FILES)
        qt_add_translation(QM_FILES ${TS_FILES_OLD} ${TS_FILES_NEW})
      endif()

      if (DEFINED QM_FILES)
        set(SOURCE_FILES ${SOURCE_FILES} ${QM_FILES})
      endif()

      if (DEFINED TS_FILES_OLD)
        set(SOURCE_FILES ${SOURCE_FILES} ${TS_FILES_OLD})
      endif()

      if (${PROJECT_TYPE} STREQUAL "LIBRARY")
        add_library(${PROJECT_NAME} ${SOURCE_FILES})
      elseif(${PROJECT_TYPE} STREQUAL "EXECUTABLE")
        add_executable(${PROJECT_NAME} ${SOURCE_FILES})

        if (WIN32)
          if(NOT BUILD_ENABLE_CONSOLE)
            set_property(TARGET ${PROJECT_NAME} PROPERTY WIN32_EXECUTABLE true)
          endif()
        endif()
      elseif(${PROJECT_TYPE} STREQUAL "INTERFACE")
        add_library(${PROJECT_NAME} INTERFACE ${SOURCE_FILES})
      else()
        message(FATAL_ERROR "unexpected argument at make_projects_type")
      endif()

      if (DEFINED PROJECT_${PROJECT_NAME}_UIC_DIRECTORIES)
        set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY AUTOUIC_SEARCH_PATHS ${PROJECT_${PROJECT_NAME}_UIC_DIRECTORIES})
      endif()

      if (DEFINED PROJECT_${PROJECT_NAME}_AUTOMOC)
        foreach(CONFIGURATION_TYPE IN ITEMS ${CMAKE_CONFIGURATION_TYPES})
          source_group(GeneratedFiles FILES
            ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_autogen/mocs_compilation_${CONFIGURATION_TYPE}.cpp)
        endforeach()
      endif()

      foreach (SOURCE_DIR IN ITEMS ${PROJECT_${PROJECT_NAME}_SOURCE_DIRECTORIES})
        source_group("${SOURCE_DIR}" FILES ${PROJECT_${PROJECT_NAME}_SOURCE_DIR_${SOURCE_DIR}})
      endforeach()

      if (DEFINED PROJECT_${PROJECT_NAME}_QRC_FILES)
        source_group(Resources FILES ${PROJECT_${PROJECT_NAME}_QRC_FILES})
      endif()

      if (DEFINED PROJECT_${PROJECT_NAME}_TS_FILES)
        source_group(Translations FILES ${PROJECT_${PROJECT_NAME}_TS_FILES})
      endif()

      if (DEFINED TS_FILES_OLD AND DEFINED PROJECT_${PROJECT_NAME}_TS_FILES_DIRECTORY)
        source_group(${PROJECT_${PROJECT_NAME}_TS_FILES_DIRECTORY} FILES ${TS_FILES_OLD})
      endif()

      if (DEFINED QM_FILES)
        source_group(GeneratedFiles/${PROJECT_${PROJECT_NAME}_TS_FILES_DIRECTORY} FILES ${QM_FILES})
      endif()

      if (DEFINED QM_FILES AND
          DEFINED TS_FILES_OLD AND
          DEFINED TRANSLATED_DIRECTORIES)

          set(LUPDATE_COMMANDS ${LUPDATE_COMMANDS}
              COMMAND ${LUPDATE_PATH} -I ${PROJECT_${PROJECT_NAME}_SOURCE_DIR} ${TRANSLATED_DIRECTORIES}
                                      -ts ${TS_FILES_OLD} ${TS_FILES_NEW})

      endif()

      set_target_properties(${PROJECT_NAME} PROPERTIES DEBUG_POSTFIX "d")

      if (DEFINED PROJECT_${PROJECT_NAME}_DEFINITIONS)
        add_definitions(${PROJECT_${PROJECT_NAME}_DEFINITIONS})
      endif()

      if(${PROJECT_TYPE} STREQUAL "INTERFACE")
        set(VISIBILITY_FLAG "INTERFACE")
      else()
        set(VISIBILITY_FLAG "PUBLIC")
      endif()

      target_include_directories(${PROJECT_NAME} ${VISIBILITY_FLAG}
        ${PROJECT_${PROJECT_NAME}_SOURCE_DIR})

      if (DEFINED PROJECT_${PROJECT_NAME}_INCLUDE_DIRECTORIES)
        target_include_directories(${PROJECT_NAME} ${VISIBILITY_FLAG}
          ${PROJECT_${PROJECT_NAME}_INCLUDE_DIRECTORIES})
      endif()

      foreach (LIBRARY_NAME IN ITEMS ${PROJECT_${PROJECT_NAME}_REQUIRED_LIBRARIES})
        function(get_include_directories OUTPUT)
        endfunction()
        function(get_library_files_debug OUTPUT)
        endfunction()
        function(get_library_files_release OUTPUT)
        endfunction()

        if (EXISTS ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
          include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
        endif()

        unset(INCLUDE_DIRECTORIES)
        get_include_directories(INCLUDE_DIRECTORIES ${PROJECT_${PROJECT_NAME}_LIBRARY_${LIBRARY_NAME}_MODULES})

        if (DEFINED INCLUDE_DIRECTORIES)
          target_include_directories(${PROJECT_NAME} ${VISIBILITY_FLAG}
            ${INCLUDE_DIRECTORIES})
        endif()

        if(${PROJECT_TYPE} STREQUAL "EXECUTABLE")
          unset(LIBRARY_FILES_DEBUG)
          unset(LIBRARY_FILES_RELEASE)

          get_library_files_debug(LIBRARY_FILES_DEBUG ${PROJECT_${PROJECT_NAME}_LIBRARY_${LIBRARY_NAME}_MODULES})
          get_library_files_release(LIBRARY_FILES_RELEASE ${PROJECT_${PROJECT_NAME}_LIBRARY_${LIBRARY_NAME}_MODULES})

          if (DEFINED LIBRARY_FILES_DEBUG)
            foreach(LIBRARY_FILE IN ITEMS ${LIBRARY_FILES_DEBUG})
              target_link_libraries(${PROJECT_NAME} debug ${LIBRARY_FILE})
            endforeach()
          endif()

          if (DEFINED LIBRARY_FILES_RELEASE)
            if (NOT DEFINED LIBRARY_FILES_DEBUG)
              target_link_libraries(${PROJECT_NAME} ${LIBRARY_FILES_RELEASE})
            else()
              foreach(LIBRARY_FILE IN ITEMS ${LIBRARY_FILES_RELEASE})
                target_link_libraries(${PROJECT_NAME} optimized ${LIBRARY_FILE})
              endforeach()
            endif()
          endif()
        endif()
      endforeach()

      foreach (PROJECT_REQ_NAME IN ITEMS ${PROJECT_${PROJECT_NAME}_REQUIRED_PROJECTS})
        if (DEFINED PROJECT_${PROJECT_REQ_NAME}_INCLUDE_DIRECTORIES)
          target_include_directories(${PROJECT_NAME} ${VISIBILITY_FLAG} ${PROJECT_${PROJECT_REQ_NAME}_INCLUDE_DIRECTORIES})
        endif()

        target_link_libraries(${PROJECT_NAME} ${PROJECT_REQ_NAME})
      endforeach()

      if (DEFINED PROJECT_${PROJECT_NAME}_AUTOMOC)
        set(CMAKE_AUTOMOC OFF)
      endif()
      if (DEFINED PROJECT_${PROJECT_NAME}_AUTORCC)
        set(CMAKE_AUTORCC OFF)
      endif()
      if (DEFINED PROJECT_${PROJECT_NAME}_AUTOUIC)
        set(CMAKE_AUTORUIC OFF)
      endif()

    endif()
  endforeach()

endmacro()

function(copy_binaries)

  foreach (LIBRARY_NAME IN ITEMS ${REQUIRED_LIBRARIES})

    if (EXISTS ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
      function(get_binary_files OUTPUT)
      endfunction()
      function(required_library_exists BOOL)
        set(${BOOL} UNDEFINED PARENT_SCOPE)
      endfunction()

      include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)

      required_library_exists(BOOL ${LIBRARY_${LIBRARY_NAME}_MODULES})
      if (${BOOL} STREQUAL "TRUE")

        unset(BINARY_FILES)
        get_binary_files(BINARY_FILES ${LIBRARY_${LIBRARY_NAME}_MODULES})
        if (DEFINED BINARY_FILES)
          message(STATUS "Copying binaries for library ${LIBRARY_NAME}")
          foreach(BINARY_FILE IN ITEMS ${BINARY_FILES})
            get_filename_component(TMP_FILENAME ${BINARY_FILE} NAME)

            configure_file(${BINARY_FILE} ${CMAKE_BINARY_DIR}/${PROJECT_BIN_DIR}/${TMP_FILENAME} COPYONLY)
          endforeach()
        endif()
        
      endif()
    endif()

  endforeach()

endfunction()

macro(make_projects)

  set(PROJECTS_CHANGED "TRUE")
  while (${PROJECTS_CHANGED} STREQUAL "TRUE")
    find_required_projects(${PROJECTS_LIBRARY} ${PROJECTS_EXECUTABLE} ${PROJECTS_INTERFACE})
  endwhile()

  find_dependencies()

  check_dependencies(${PROJECTS_LIBRARY} ${PROJECTS_EXECUTABLE} ${PROJECTS_INTERFACE})

  make_projects_type("${PROJECTS_LIBRARY}" LIBRARY)
  make_projects_type("${PROJECTS_EXECUTABLE}" EXECUTABLE)
  make_projects_type("${PROJECTS_INTERFACE}" INTERFACE)

  if (DEFINED LUPDATE_COMMANDS)
    add_custom_target(lupdate ${LUPDATE_COMMANDS})
  endif()

  if (MSVC)
    copy_binaries()
  endif()

  configure_file(${CMAKE_SCRIPTS_DIRECTORY}/.clang-format ${CMAKE_BINARY_DIR}/.clang-format COPYONLY)

endmacro()