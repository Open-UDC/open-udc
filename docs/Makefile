#!/usr/bin/make

SUBDIRS = pdf

.PHONY: clean $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	cd '$@' && make

clean: cleansubdirs

cleansubdirs:
	for i in $(SUBDIRS) ; do ( \
		cd $$i ; \
		make clean \
	) ; done

