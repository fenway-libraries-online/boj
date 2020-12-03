-include config.mk

SOURCES = $(PROG) $(PROG).pod Makefile README LICENSE config.mk example
MACROS = -D__PROG__="$(PROG)" -D__VERSION__="$(VERSION)" -D__AUTHOR__="$(AUTHOR)" -D__COPYRIGHT__="$(COPYRIGHT)" \
		 -D__PREFIX__="$(PREFIX)" -D__BINDIR__="$(BINDIR)" -D__MANDIR__="$(MANDIR)" -D__SENDMAIL__="$(SENDMAIL)" \
		 -D__UCPROG__="$(UCPROG)"

default: $(PROG).tmp $(PROG).1

config.mk: config.mk.def
	cp $< $@

$(PROG).tmp: $(PROG) config.mk
	m4 $(MACROS) $< > $@

$(PROG).1: $(PROG).pod
	m4 $(MACROS) $< | pod2man --section=1 --release="$(PROG) $(VERSION)" --center='Utils' --name="$(shell echo $(PROG) | tr a-z A-Z)" > $@
#m4 $(MACROS) $< > $@

install: $(PROG).tmp $(PROG).1
	mkdir -p $(BINDIR) $(MANDIR)
	install $(PROG).tmp $(BINDIR)/$(PROG)
	install $(PROG).1 $(MANDIR)/$(PROG).1

dist: $(PROG)-$(VERSION).tar.gz

$(PROG)-$(VERSION).tar.gz: $(PROG)-$(VERSION)
	tar -czf $@ $<

$(PROG)-$(VERSION): $(SOURCES)
	rm -Rf $@
	mkdir $@
	cp -r $(SOURCES) $@/

clean:
	rm -Rf $(PROG)-*.*.* *.bak *.tmp

.PHONY: default install dist clean diffpod
