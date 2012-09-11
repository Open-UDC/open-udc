CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

######################################################################################
### 0) If you want to set your variables in openudc-conf.cmake and avoid the cmd line
######################################################################################

INCLUDE(../openudc-conf.cmake OPTIONAL)

######################################################################################


######################################################################################
### 1) Main project config
######################################################################################

# set the project name and other variables
PROJECT(ludd)

# set the project version
SET(PROJECT_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}" CACHE STRING "Package version" FORCE)
SET(VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}${PROJECT_VERSION_MISC}" CACHE STRING "Global version" FORCE)
SET(GLOBAL_VERSION "${VERSION}")

# set other variables useful for packaging
SET(PACKAGE_BUGREPORT "open-udc@googlegroups.com" CACHE STRING "Package bug report" FORCE)
SET(PACKAGE_NAME "Lucid Universal Dividend Daemon" CACHE STRING "Package name" FORCE)
SET(PACKAGE_STRING "${PACKAGE_NAME} ${PACKAGE_VERSION}"CACHE STRING "Package string full name" FORCE)
SET(PACKAGE_TARNAME "ludd" CACHE STRING "Package tar name" FORCE)

INCLUDE(FindDoxygen)

If(NOT EXECUTABLE_OUTPUT_PATH)
  SET(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})
ENDIF(NOT EXECUTABLE_OUTPUT_PATH)

######################################################################################


######################################################################################
### 2) Where must cmake go now ?
######################################################################################

ADD_SUBDIRECTORY(doxydocs)
ADD_SUBDIRECTORY(scripts)
ADD_SUBDIRECTORY(src)
ADD_SUBDIRECTORY(udid2js)

######################################################################################


######################################################################################
### 3) Include packaging
######################################################################################

INCLUDE(Packaging.cmake)

######################################################################################
