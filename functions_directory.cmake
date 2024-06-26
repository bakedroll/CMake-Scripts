function(add_files ADD_FILES_OUTPUT ADD_FILES_NAME ADD_FILES_EXTENSION)

  file(GLOB_RECURSE FILES_SOURCE_TMP RELATIVE
    "${CMAKE_CURRENT_SOURCE_DIR}/${ADD_FILES_NAME}"
    "${CMAKE_CURRENT_SOURCE_DIR}/${ADD_FILES_NAME}/*.${ADD_FILES_EXTENSION}")
    
  set(FILES_OUTPUT_TMP "")
  foreach(FILE_NAME ${FILES_SOURCE_TMP})
    list(APPEND FILES_OUTPUT_TMP ${CMAKE_CURRENT_SOURCE_DIR}/${ADD_FILES_NAME}/${FILE_NAME})
  endforeach()
 
  set(${ADD_FILES_OUTPUT} ${${ADD_FILES_OUTPUT}} ${FILES_OUTPUT_TMP} PARENT_SCOPE)
  
endfunction()

macro(add_project_source_dir PROJECT_NAME TRANSLATED)

  foreach(FILE_NAME IN ITEMS ${ARGN})
    file(RELATIVE_PATH REL_FILE_PATH ${CMAKE_CURRENT_SOURCE_DIR} ${FILE_NAME})
    get_filename_component(REL_PATH ${REL_FILE_PATH} DIRECTORY)

    set_parent_scope(PROJECT_${PROJECT_NAME}_SOURCE_DIRECTORIES ${PROJECT_${PROJECT_NAME}_SOURCE_DIRECTORIES} ${REL_PATH})
    set_parent_scope(PROJECT_${PROJECT_NAME}_SOURCE_DIR_${REL_PATH} ${PROJECT_${PROJECT_NAME}_SOURCE_DIR_${REL_PATH}} ${FILE_NAME})

    if (${TRANSLATED} STREQUAL "TRANSLATED")
      set_parent_scope(PROJECT_${PROJECT_NAME}_TRANSLATED_DIRECTORIES ${PROJECT_${PROJECT_NAME}_TRANSLATED_DIRECTORIES} ${REL_PATH})
    endif()
  endforeach()

endmacro()

macro(add_source_directory ADD_SOURCE_DIRECTORY_NAME)
  
  set(ADD_SOURCE_DIRECTORY_OUTPUT_TMP "")
  add_files(ADD_SOURCE_DIRECTORY_OUTPUT_TMP ${ADD_SOURCE_DIRECTORY_NAME} "cpp")
  add_files(ADD_SOURCE_DIRECTORY_OUTPUT_TMP ${ADD_SOURCE_DIRECTORY_NAME} "h")
  
  add_project_source_dir(${CURRENT_PROJECT_NAME} TRANSLATED ${ADD_SOURCE_DIRECTORY_OUTPUT_TMP})

endmacro()

macro(add_ui_directory ADD_UI_DIRECTORY_NAME)
  
  set(ADD_UI_DIRECTORY_OUTPUT_TMP "")
  add_files(ADD_UI_DIRECTORY_OUTPUT_TMP ${ADD_UI_DIRECTORY_NAME} "ui")
  
  add_project_source_dir(${CURRENT_PROJECT_NAME} TRANSLATED ${ADD_UI_DIRECTORY_OUTPUT_TMP})

  set_parent_scope(
    PROJECT_${CURRENT_PROJECT_NAME}_UIC_DIRECTORIES
    ${PROJECT_${CURRENT_PROJECT_NAME}_UIC_DIRECTORIES}
    ${CMAKE_CURRENT_SOURCE_DIR}/${ADD_UI_DIRECTORY_NAME})

endmacro()

macro(add_other_directory ADD_OTHER_DIRECTORY_NAME)
  
  set(ADD_OTHER_DIRECTORY_OUTPUT_TMP "")
  add_files(ADD_OTHER_DIRECTORY_OUTPUT_TMP ${ADD_OTHER_DIRECTORY_NAME} "*")

  add_project_source_dir(${CURRENT_PROJECT_NAME} UNTRANSLATED ${ADD_OTHER_DIRECTORY_OUTPUT_TMP})

endmacro()

macro(add_include_directory ADD_INCLUDE_DIRECTORY_NAME)

  set_parent_scope(
    PROJECT_${CURRENT_PROJECT_NAME}_INCLUDE_DIRECTORIES
    ${PROJECT_${CURRENT_PROJECT_NAME}_INCLUDE_DIRECTORIES}
    ${CMAKE_CURRENT_SOURCE_DIR}/${ADD_INCLUDE_DIRECTORY_NAME})

endmacro()

macro(add_qrc_files)

  foreach(FILE_NAME IN ITEMS ${ARGN})
    set_parent_scope(
      PROJECT_${CURRENT_PROJECT_NAME}_QRC_FILES
      ${PROJECT_${CURRENT_PROJECT_NAME}_QRC_FILES}
      ${CMAKE_CURRENT_SOURCE_DIR}/${FILE_NAME})
  endforeach()

endmacro()

macro(add_ts_files)

  foreach(FILE_NAME IN ITEMS ${ARGN})
    set_parent_scope(
      PROJECT_${CURRENT_PROJECT_NAME}_TS_FILES
      ${PROJECT_${CURRENT_PROJECT_NAME}_TS_FILES}
      ${CMAKE_CURRENT_SOURCE_DIR}/${FILE_NAME})
  endforeach()

endmacro()

macro(set_qm_directory QM_DIRECTORY)

  set_parent_scope(PROJECT_${CURRENT_PROJECT_NAME}_QM_DIRECTORY ${QM_DIRECTORY})

endmacro()