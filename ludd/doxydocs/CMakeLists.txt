##########################################################################################
### LUDD Doc generation using Doxygen
##########################################################################################

IF (DOXYGEN_FOUND)

  SET(DOC_DIR ${ludd_BINARY_DIR}/doc CACHE PATH "LUDD documentation directory")
  SET(LUDD_DOC_CONFIG_FILE "doxygen" CACHE PATH "LUDD documentation configuration file")

  # Copy necessary doc files
  CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/index.h ${DOC_DIR}/index.h COPYONLY)
  FILE(GLOB header_files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/*.htm*)
  FILE(GLOB pdf_files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/*.pdf)
  FILE(GLOB jpg_files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/*.jpg)
  FOREACH (file ${header_files} ${pdf_files} ${jpg_files})
    CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/${file} ${DOC_DIR}/${file} COPYONLY)
  ENDFOREACH (file)

  # define the doc target
  IF (DOXYGEN_EXECUTABLE)
    ADD_CUSTOM_TARGET(ludd-doc
      COMMAND ${DOXYGEN_EXECUTABLE} ${LUDD_DOC_CONFIG_FILE}
      WORKING_DIRECTORY ${DOC_DIR}
      )
  ENDIF (DOXYGEN_EXECUTABLE)

  # configure cfg file
  CONFIGURE_FILE(
    "${ludd_SOURCE_DIR}/doxydocs/${LUDD_DOC_CONFIG_FILE}.cmake"
    "${ludd_BINARY_DIR}/doc/${LUDD_DOC_CONFIG_FILE}"
    )

  INSTALL(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    DESTINATION share/ludd COMPONENT libraries
    PATTERN "CMakeFiles" EXCLUDE
    PATTERN "cmake_install.cmake" EXCLUDE
    PATTERN "Makefile" EXCLUDE
    PATTERN "doxygen" EXCLUDE
    PATTERN "ludd.doxytag" EXCLUDE
    )
ELSE (DOXYGEN_FOUND)
  MESSAGE(STATUS "Unable to generate the documentation, Doxygen package not found")
ENDIF (DOXYGEN_FOUND)
