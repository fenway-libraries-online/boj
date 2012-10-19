include config.mk

SOURCES = $(PROG) $(PROG).1 Makefile README LICENSE config.mk example

metadata:
	@VERSION="$(VERSION)" AUTHOR="$(AUTHOR)" COPYRIGHT="$(COPYRIGHT)" \
		perl -i -pe 'BEGIN { undef $$/ } s/^(\.\\" @(\w+)\n)([^\n]*)/$$1$$ENV{$$2}/mgs' boj boj.1

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

.PHONY: default metadata install dist clean
