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

      include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)
    else()
      message(FATAL_ERROR "No script ${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake provided")
    endif()

    find_required_library(${LIBRARY_${LIBRARY_NAME}_MODULES})

  endforeach()

endmacro()

function(check_dependencies)

  foreach(PROJECT_NAME IN ITEMS ${ARGV})
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
  list(REMOVE_DUPLICATES EXCLUDED_PROJECTS)

  list(REMOVE_ITEM LIBRARIES_MISSING_OPTIONAL ${LIBRARIES_MISSING})

  foreach (LIB IN ITEMS ${LIBRARIES_MISSING})
    message(SEND_ERROR "Required dependency ${LIB} missing or incomplete")
  endforeach()

  foreach (LIB IN ITEMS ${LIBRARIES_MISSING_OPTIONAL})
    message(WARNING "Optional dependency ${LIB} missing or incomplete")
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
      #target_compile_options(${PROJECT_NAME} PRIVATE "-fpermissive")

      if (DEFINED PROJECT_${PROJECT_NAME}_INCLUDE_DIRECTORIES)
        target_include_directories(${PROJECT_NAME} PUBLIC ${PROJECT_${PROJECT_NAME}_INCLUDE_DIRECTORIES})
        #message(STATUS ${PROJECT_${PROJECT_NAME}_INCLUDE_DIRECTORIES})
      endif()

      foreach (LIBRARY_NAME IN ITEMS ${PROJECT_${PROJECT_NAME}_REQUIRED_LIBRARIES})
        include(${CMAKE_SCRIPTS_DIRECTORY}/${LIBRARY_NAME}.cmake)

        get_include_directories(INCLUDE_DIRECTORIES)
        target_include_directories(${PROJECT_NAME} PUBLIC ${INCLUDE_DIRECTORIES})
      endforeach()

    endif()
  endforeach()

endmacro()


function(make_projects)

  find_dependencies()

  check_dependencies(${PROJECTS_LIBRARY} ${PROJECTS_EXECUTABLE})

  make_projects_type("${PROJECTS_LIBRARY}" LIBRARY)
  make_projects_type("${PROJECTS_EXECUTABLE}" EXECUTABLE)

endfunction()