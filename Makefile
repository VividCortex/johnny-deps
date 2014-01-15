-include ./config.make

all:
	-@echo Nothing to do...

install:
	install -d $(prefix)/bin
	install -m 0755 bin/jd $(prefix)/bin

test:
	-@echo Tests are temporarily disabled
	-@echo Nothing to see here... move along

.PHONY: all install test
