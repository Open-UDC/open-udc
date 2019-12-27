#!/usr/bin/make


SRC= $(shell find ../src -name "*.md" | sed 's:../src/:: ; s: :\\ :g' )
PDF= $(SRC:.md=.pdf)
SVGSRC= $(shell find ../src -name "*.svg" | sed 's:../src/:: ; s: :\\ :g' )
PNG= $(SVGSRC:.svg=.png)

.PHONY: clean

all: $(PNG) $(PDF)

$(PNG):
	convert '../src/$(subst .png,.svg,$@)' '$@'

$(PDF):
	pandoc -N --default-image-extension=png -F ../src/graphviz.py \
		--latex-engine=xelatex --template=OpenUDCtemplate.latex \
		-o '$@' '../src/$(subst .pdf,.md,$@)'

clean:
	rm -vf $(PDF) $(PNG)

