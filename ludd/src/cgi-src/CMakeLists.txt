ADD_EXECUTABLE(redirect redirect.c)
ADD_EXECUTABLE(ssi ssi.c)
TARGET_LINK_LIBRARIES(ssi match)
ADD_EXECUTABLE(phf phf.c)
