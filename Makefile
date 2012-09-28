include config.mk

SOURCES = $(PROG) $(PROG).1 Makefile README LICENSE config.mk example

default:
	@echo "You must specify a target: install or dist."

install: $(PROG) $(PROG).1
	mkdir -p $(BINDIR) $(MANDIR)
	install $(PROG) $(BINDIR)/
	install $(PROG).1 $(MANDIR)

dist: $(PROG)-$(VERSION).tar.gz

$(PROG)-$(VERSION).tar.gz: $(PROG)-$(VERSION)
	tar -czf $@ $<

$(PROG)-$(VERSION): $(SOURCES)
	mkdir $@
	cp -r $(SOURCES) $@/

clean:
	rm -Rf $(PROG)-$(VERSION)*

.PHONY: default install dist clean
