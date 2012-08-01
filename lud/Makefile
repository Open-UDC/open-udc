# Makefile for lud
#

DEST_DIR =	/usr/local/bin

all:
	# Nothing to compile, run directly "make install" (as root)

install:
	install -m 555 src/lud_genudid.sh src/lud.sh $(DEST_DIR)
	install -m 444 src/lud_set.env src/lud_utils.env src/lud_generator.env $(DEST_DIR)

uninstall:
	rm -vf $(DEST_DIR)/lud_genudid.sh $(DEST_DIR)/lud_*.env

