include config.mk

SOURCES = $(PROG) $(PROG).1 Makefile README LICENSE config.mk example

default: $(PROG).tmp $(PROG).1.tmp

$(PROG).tmp: $(PROG) config.mk
	m4 -D__VERSION__="$(VERSION)" -D__AUTHOR__="$(AUTHOR)" -D__COPYRIGHT__="$(COPYRIGHT)" $< > $@

$(PROG).1.tmp: $(PROG).1 config.mk
	m4 -D__VERSION__="$(VERSION)" -D__AUTHOR__="$(AUTHOR)" -D__COPYRIGHT__="$(COPYRIGHT)" $< > $@

install: $(PROG).tmp $(PROG).1.tmp
	mkdir -p $(BINDIR) $(MANDIR)
	install $(PROG).tmp $(BINDIR)/$(PROG)
	install $(PROG).1.tmp $(MANDIR)/$(PROG).1

dist: $(PROG)-$(VERSION).tar.gz

$(PROG)-$(VERSION).tar.gz: $(PROG)-$(VERSION)
	tar -czf $@ $<

$(PROG)-$(VERSION): $(SOURCES)
	rm -Rf $@
	mkdir $@
	cp -r $(SOURCES) $@/

clean:
	rm -Rf $(PROG)-*.*.* *.bak *.tmp

.PHONY: default install dist clean
