PREFIX ?= /usr/local

install:
	install -d $(PREFIX)/bin
	install -m 755 prhook.sh $(PREFIX)/bin/prhook
	@echo "Installed! Run 'prhook --help"

uninstall:
	rm -f $(PREFIX)/bin/prhook
	@echo "Uninstalled!"
