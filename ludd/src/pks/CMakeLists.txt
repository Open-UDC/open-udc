ADD_EXECUTABLE(cgi-add cgi-add.c)
ADD_EXECUTABLE(cgi-lookup cgi-lookup.c)
INSTALL(TARGETS cgi-add cgi-lookup RUNTIME DESTINATION bin COMPONENT applications)
