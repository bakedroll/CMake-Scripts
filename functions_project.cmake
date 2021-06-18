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

macro(find_required_projects)

  set(PROJECTS_DIRECTORY "" CACHE STRING "The directory where external projects are located")

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

    set(ALL_PROJECTS ${PROJECTS_LIBRARY} ${PROJECTS_EXECUTABLE})
    list(FIND ALL_PROJECTS ${PROJECT_TO_ADD} PROJECT_ADDED_INDEX)
    if (${PROJECT_ADDED_INDEX} LESS 0)
      set(PROJECTS_FAILED_TO_ADD ${PROJECTS_FAILED_TO_ADD} ${PROJECT_TO_ADD})
    endif()

  endforeach()

endmacro()

macro(find_dependencies)

  foreach (LIBRARY_NAME IN ITEMS ${REQUIRED_LIBRARIES})

    if (EXISTS ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
      macro(find_required_library)
        find_package(${LIBRARY_NAME} COMPONENTS ${ARGV})
      endmacro()
      macro(find_required_binaries)
      endmacro()

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

      foreach (QRC_FILE IN ITEMS ${PROJECT_${PROJECT_NAME}_QRC_FILES})
        set(SOURCE_FILES ${SOURCE_FILES} ${QRC_FILE})
      endforeach()

      message(STATUS "Generating project ${PROJECT_NAME}")

      if (DEFINED PROJECT_${PROJECT_NAME}_AUTOMOC)
        set(CMAKE_AUTOMOC ON)
      endif()
      if (DEFINED PROJECT_${PROJECT_NAME}_AUTORCC)
        set(CMAKE_AUTORCC ON)
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
      else()
        message(FATAL_ERROR "unexpected argument at make_projects_type")
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

      set_target_properties(${PROJECT_NAME} PROPERTIES DEBUG_POSTFIX "d")

      if (DEFINED PROJECT_${PROJECT_NAME}_DEFINITIONS)
        add_definitions(${PROJECT_${PROJECT_NAME}_DEFINITIONS})
      endif()

      target_include_directories(${PROJECT_NAME} PUBLIC ${PROJECT_${PROJECT_NAME}_SOURCE_DIR})

      if (DEFINED PROJECT_${PROJECT_NAME}_INCLUDE_DIRECTORIES)
        target_include_directories(${PROJECT_NAME} PUBLIC ${PROJECT_${PROJECT_NAME}_INCLUDE_DIRECTORIES})
      endif()

      foreach (LIBRARY_NAME IN ITEMS ${PROJECT_${PROJECT_NAME}_REQUIRED_LIBRARIES})
        function(get_include_directories OUTPUT)
        endfunction()
        function(get_library_files_debug OUTPUT)
        endfunction()
        function(get_library_files_release OUTPUT)
        endfunction()

        include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)

        unset(INCLUDE_DIRECTORIES)
        get_include_directories(INCLUDE_DIRECTORIES ${PROJECT_${PROJECT_NAME}_LIBRARY_${LIBRARY_NAME}_MODULES})

        if (DEFINED INCLUDE_DIRECTORIES)
          target_include_directories(${PROJECT_NAME} PUBLIC ${INCLUDE_DIRECTORIES})
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
          target_include_directories(${PROJECT_NAME} PUBLIC ${PROJECT_${PROJECT_REQ_NAME}_INCLUDE_DIRECTORIES})
        endif()

        target_link_libraries(${PROJECT_NAME} ${PROJECT_REQ_NAME})
      endforeach()

      if (DEFINED PROJECT_${PROJECT_NAME}_AUTOMOC)
        set(CMAKE_AUTOMOC OFF)
      endif()
      if (DEFINED PROJECT_${PROJECT_NAME}_AUTORCC)
        set(CMAKE_AUTORCC OFF)
      endif()

    endif()
  endforeach()

endmacro()

function(copy_binaries)

  foreach (LIBRARY_NAME IN ITEMS ${REQUIRED_LIBRARIES})

    if (EXISTS ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
      function(get_binary_files OUTPUT)
      endfunction()

      include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)

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

  endforeach()

endfunction()

macro(make_projects)

  set(PROJECTS_CHANGED "TRUE")
  while (${PROJECTS_CHANGED} STREQUAL "TRUE")
    find_required_projects(${PROJECTS_LIBRARY} ${PROJECTS_EXECUTABLE})
  endwhile()

  find_dependencies()

  check_dependencies(${PROJECTS_LIBRARY} ${PROJECTS_EXECUTABLE})

  make_projects_type("${PROJECTS_LIBRARY}" LIBRARY)
  make_projects_type("${PROJECTS_EXECUTABLE}" EXECUTABLE)

  if (MSVC)
    copy_binaries()
  endif()

  configure_file(${CMAKE_SCRIPTS_DIRECTORY}/.clang-format ${CMAKE_BINARY_DIR}/.clang-format COPYONLY)

endmacro()