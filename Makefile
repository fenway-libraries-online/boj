include config.mk

SOURCES = $(PROG) $(PROG).1 Makefile README LICENSE config.mk example

default:
	@echo "You must specify a target (install or dist)"

metadata:
	@sed -i.bak -e "s/ @@VERSION.*/ @@VERSION $(VERSION)/"       \
	       -e "s/ @@AUTHOR.*/ @@AUTHOR $(AUTHOR)/"          \
	       -e "s/ @@COPYRIGHT.*/ @@COPYRIGHT $(COPYRIGHT)/" \
	       boj boj.1

foo:
	perl -i -pe "s/ @@VERSION.*/ @@VERSION $(VERSION)/;
	@VERSION="$(VERSION)" AUTHOR="$(AUTHOR)" COPYRIGHT="$(COPYRIGHT)" \
		perl -i -pe 's/ @@(VERSION|AUTHOR|COPYRIGHT).*/ \@\@$$1 $$ENV{$$1}/' boj boj.1

install: $(PROG) $(PROG).1
	mkdir -p $(BINDIR) $(MANDIR)
	install $(PROG) $(BINDIR)/
	install $(PROG).1 $(MANDIR)

dist: $(PROG)-$(VERSION).tar.gz

$(PROG)-$(VERSION).tar.gz: $(PROG)-$(VERSION)
	tar -czf $@ $<

$(PROG)-$(VERSION): metadata $(SOURCES)
	mkdir $@
	cp -r $(SOURCES) $@/

clean:
	rm -Rf $(PROG)-*.*.*

.PHONY: default metadata install dist clean
