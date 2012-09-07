SET(USERLUDD "ludd")
SET(HOMEDIR ${CMAKE_INSTALL_PREFIX}/var/ludd)
EXECUTE_PROCESS(COMMAND useradd -r -c "system user for ludd" -d "${HOMEDIR}" -s /sbin/nologin ${USERLUDD})
EXECUTE_PROCESS(COMMAND chown -R ${USERLUDD} "${HOMEDIR}")
