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
  else()
    message(FATAL_ERROR "unexpected argument at begin_project")
  endif()

  if ("${ARGN}" STREQUAL "OPTIONAL")
    set_parent_scope(PROJECT_${PROJECT_NAME}_OPTIONAL TRUE)
  endif()

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

macro(require_project PROJECT_NAME)

  set_parent_scope(
    PROJECT_${CURRENT_PROJECT_NAME}_REQUIRED_PROJECTS
    ${PROJECT_${CURRENT_PROJECT_NAME}_REQUIRED_PROJECTS} ${PROJECT_NAME})

endmacro()

macro(find_dependencies)

  foreach (LIBRARY_NAME IN ITEMS ${REQUIRED_LIBRARIES})

    if (EXISTS ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
      function(find_required_library)
        find_package(${LIBRARY_NAME} COMPONENTS ${ARGV})
      endfunction()
      function(find_required_binaries)
      endfunction()

      include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
    else()
      message(FATAL_ERROR "No script ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake provided")
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

      if (EXISTS ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
        include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
      endif()

      if (COMMAND required_library_exists)
        required_library_exists(BOOL ${PROJECT_${PROJECT_NAME}_LIBRARY_${LIBRARY_NAME}_MODULES})

        if (${BOOL} STREQUAL "FALSE")
          if ("${PROJECT_${PROJECT_NAME}_OPTIONAL}" STREQUAL "TRUE")
            set(LIBRARIES_MISSING_OPTIONAL ${LIBRARIES_MISSING_OPTIONAL} ${LIBRARY_NAME})
            set_parent_scope(EXCLUDED_PROJECTS ${EXCLUDED_PROJECTS} ${PROJECT_NAME})
          else()
            set(LIBRARIES_MISSING ${LIBRARIES_MISSING} ${LIBRARY_NAME})
          endif()
        endif()
      else()
        message(FATAL_ERROR "Missing function required_library_exists() for library ${LIBRARY_NAME}")
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

    list(FIND EXCLUDED_PROJECTS ${PROJECT_NAME} EXCLUDED_PROJECT_INDEX)
    if (${EXCLUDED_PROJECT_INDEX} LESS 0)

      set(SOURCE_FILES "")
      foreach (SOURCE_DIR IN ITEMS ${PROJECT_${PROJECT_NAME}_SOURCE_DIRECTORIES})
        set(SOURCE_FILES ${SOURCE_FILES} ${PROJECT_${PROJECT_NAME}_SOURCE_DIR_${SOURCE_DIR}})
      endforeach()

      message(STATUS "Generating project ${PROJECT_NAME}")

      if (${PROJECT_TYPE} STREQUAL "LIBRARY")
        add_library(${PROJECT_NAME} ${SOURCE_FILES})
      elseif(${PROJECT_TYPE} STREQUAL "EXECUTABLE")
        add_executable(${PROJECT_NAME} ${SOURCE_FILES})
      else()
        message(FATAL_ERROR "unexpected argument at make_projects_type")
      endif()

      foreach (SOURCE_DIR IN ITEMS ${PROJECT_${PROJECT_NAME}_SOURCE_DIRECTORIES})
        source_group("${SOURCE_DIR}" FILES ${PROJECT_${PROJECT_NAME}_SOURCE_DIR_${SOURCE_DIR}})
      endforeach()

      set_target_properties(${PROJECT_NAME} PROPERTIES DEBUG_POSTFIX "d")

      if (DEFINED PROJECT_${PROJECT_NAME}_INCLUDE_DIRECTORIES)
        target_include_directories(${PROJECT_NAME} PUBLIC ${PROJECT_${PROJECT_NAME}_INCLUDE_DIRECTORIES})
      endif()

      foreach (LIBRARY_NAME IN ITEMS ${PROJECT_${PROJECT_NAME}_REQUIRED_LIBRARIES})
        include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)

        get_include_directories(INCLUDE_DIRECTORIES)
        target_include_directories(${PROJECT_NAME} PUBLIC ${INCLUDE_DIRECTORIES})

        if(${PROJECT_TYPE} STREQUAL "EXECUTABLE")

          if (NOT COMMAND get_library_files_debug)
            message(FATAL_ERROR "Missing function get_library_files_debug() for library ${LIBRARY_NAME}")
          endif()
          if (NOT COMMAND get_library_files_release)
            message(FATAL_ERROR "Missing function get_library_files_release() for library ${LIBRARY_NAME}")
          endif()

          get_library_files_debug(LIBRARY_FILES_DEBUG ${PROJECT_${PROJECT_NAME}_LIBRARY_${LIBRARY_NAME}_MODULES})
          get_library_files_release(LIBRARY_FILES_RELEASE ${PROJECT_${PROJECT_NAME}_LIBRARY_${LIBRARY_NAME}_MODULES})

          if (DEFINED LIBRARY_FILES_DEBUG)
            target_link_libraries(${PROJECT_NAME} debug ${LIBRARY_FILES_DEBUG})
          endif()

          if (DEFINED LIBRARY_FILES_RELEASE)
            target_link_libraries(${PROJECT_NAME} optimized ${LIBRARY_FILES_RELEASE})
          endif()
        endif()
      endforeach()

      foreach (PROJECT_REQ_NAME IN ITEMS ${PROJECT_${PROJECT_NAME}_REQUIRED_PROJECTS})
        if (DEFINED PROJECT_${PROJECT_REQ_NAME}_INCLUDE_DIRECTORIES)
          target_include_directories(${PROJECT_NAME} PUBLIC ${PROJECT_${PROJECT_REQ_NAME}_INCLUDE_DIRECTORIES})
        endif()

        if(${PROJECT_TYPE} STREQUAL "EXECUTABLE")
          target_link_libraries(${PROJECT_NAME} ${PROJECT_REQ_NAME})
        endif()
      endforeach()


    endif()
  endforeach()

endmacro()

function(copy_binaries)

  foreach (LIBRARY_NAME IN ITEMS ${REQUIRED_LIBRARIES})

    if (EXISTS ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
      function(get_binary_files OUTPUT)
        set_parent_scope(${OUTPUT} "")
      endfunction()

      include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)

      get_binary_files(BINARY_FILES ${LIBRARY_${LIBRARY_NAME}_MODULES})
      if (DEFINED BINARY_FILES)
        message(STATUS "Copying binaries for library ${LIBRARY_NAME}")
        foreach(BINARY_FILE IN ITEMS ${BINARY_FILES})
          get_filename_component(TMP_FILENAME ${BINARY_FILE} NAME)

          configure_file(${BINARY_FILE} ${CMAKE_BINARY_DIR}/${PROJECT_BIN_DIR}/${TMP_FILENAME} COPYONLY)
        endforeach()
      endif()
    endif()

  endforeach()

endfunction()

function(make_projects)

  find_dependencies()

  check_dependencies(${PROJECTS_LIBRARY} ${PROJECTS_EXECUTABLE})

  make_projects_type("${PROJECTS_LIBRARY}" LIBRARY)
  make_projects_type("${PROJECTS_EXECUTABLE}" EXECUTABLE)

  if (MSVC)
    copy_binaries()
  endif()

endfunction()