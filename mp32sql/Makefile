.SILENT:

# $Id: Makefile,v 1.1 2004/10/20 10:29:38 nicolaw Exp $

TARGET_HOME=/home/nicolaw
TARGET_BIN=$(TARGET_HOME)/bin
TARGET_HTDOCS=$(TARGET_HOME)/webroot/www
TARGET_HTML=$(TARGET_HTDOCS)/playlists

INSTALL_CMD=/usr/bin/install
INSTALL_ARGS=-D -v -b 
INSTALL=$(INSTALL_CMD) $(INSTALL_ARGS)

default:
	echo "Available targets:"
	echo "   make install       - Install everything"
	echo "   make install_bin   - Only install binaries"
	echo "   make install_html  - Only install HTML files"

install: install_bin install_html

install_bin:
	$(INSTALL) mp32sql.pl $(TARGET_BIN)/mp32sql.pl
	$(INSTALL) sql2m3u.pl $(TARGET_BIN)/sql2m3u.pl
	$(INSTALL) UpdateMP3Database.sh $(TARGET_BIN)/UpdateMP3Database.sh

install_html:
	$(INSTALL) -m 0644 index.html $(TARGET_HTML)/index.html

