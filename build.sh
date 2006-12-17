#!/bin/bash
############################################################
#
#   $Id$
#   build.sh - mod_perl compilation and install script
#
#   Copyright 2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################
# vim:ts=4:sw=4:tw=78

#
# Edit whatever values you need to here
#

WEBROOT=$HOME/webroot
SRC=$WEBROOT/src

PERLVER=`wget -q -O - http://www.perl.org/ | grep "Current Release" | egrep -o "5\.[0-9]\.[0-9]" | head -1`
if [ "x$PERLVER" = "x" ]; then PERLVER="5.8.8" ;fi

APACHEVER=`wget -q -O - http://archive.apache.org/dist/httpd/ | egrep -o "CURRENT-IS-[0-9\.]+" | sort -n | tail -1 | sed 's/.*-//'`
if [ "x$APACHEVER" = "x" ]; then APACHEVER="2.2.2" ;fi

MODPERLVER="2.0-current"

PERL_INST_DIR=$WEBROOT/perl-$PERLVER
APACHE_INST_DIR=$WEBROOT/apache-$APACHEVER


#
# You should not need to alter anything beyond this point, unless
# you want to fiddle around with what Apache modules are made.
#

APACHE_TEST_APXS=$APACHE_INST_DIR/bin/apxs
APACHE_TEST_HTTPD=$APACHE_INST_DIR/bin/httpd
APACHE_TEST_USER=`id -un`
APACHE_TEST_GROUP=`id -gn`
export APACHE_TEST_APXS APACHE_TEST_HTTPD APACHE_TEST_USER APACHE_TEST_GROUP

APACHE_ROOT=$APACHE_INST_DIR
APACHE=$APACHE_INST_DIR/bin/httpd
export APACHE_ROOT APACHE


# Made sure our webroot exists
if ! [ -d $WEBROOT ]; then
	mkdir -p $WEBROOT
fi

# Make sure our src build directory exists
if ! [ -d $SRC ]; then
	mkdir -p $SRC
fi



# For use later on
find_extract_dir() {
	if [ $# -le 0 ]; then
		echo "fint_extract_dir() called without filename paramater; exiting"
		exit
	fi
	local path=`tar -tzf $1 | head -n 1 | cut -d'/' -f1`
	echo $path
}



# Build perl $PERLVER with ithreads
cd $SRC
TARBALL=perl-$PERLVER.tar.gz

if ! [ -d $PERL_INST_DIR ]; then
	if ! [ -f $TARBALL ]; then
		URL=ftp://ftp.cpan.org/pub/CPAN/src/$TARBALL
		wget $URL
		if ! [ -f $TARBALL ]; then
			echo "Failed to download $TARBALL from $URL"
			exit
		fi
	fi

	PERL_SRC_DIR=`find_extract_dir $TARBALL`
	if [ -d $PERL_SRC_DIR ]; then
		echo "rm -Rf $PERL_SRC_DIR"
		sleep 3
		rm -Rf $PERL_SRC_DIR
	fi

	if ! tar -zxf $TARBALL ;then
		echo "Failed to extract $TARBALL"
		exit
	fi

	if ! cd $PERL_SRC_DIR ;then
		echo "Failed to chdir to $PERL_SRC_DIR"
		exit
	fi

	CC=gcc ./Configure \
		-Dprefix=$PERL_INST_DIR \
		-Dusethreads -Duseithreads -Uuse5005threads -Dusemultiplicity \
		-Duselargefiles \
		-e -d -O \
		&& make && make install
else
	echo "Perl $PERLVER is already built; skipping ..."
	sleep 1
fi

if ! [ -d $PERL_INST_DIR ]; then
	echo; echo "Failed to build Perl $PERLVER for some reason"; echo
	exit
fi



# Build apache $APACHEVER
cd $SRC
TARBALL=httpd-$APACHEVER.tar.gz

if ! [ -d $APACHE_INST_DIR ]; then
	if ! [ -f $TARBALL ]; then
		URL=http://archive.apache.org/dist/httpd/$TARBALL
		wget $URL
		if ! [ -f $TARBALL ]; then
			echo "Failed to download $TARBALL from $URL"
			exit
		fi
	fi

	APACHE_SRC_DIR=`find_extract_dir $TARBALL`
	if [ -d $APACHE_SRC_DIR ]; then
		echo "rm -Rf $APACHE_SRC_DIR"
		sleep 3
		rm -Rf $APACHE_SRC_DIR
	fi

	if tar -zxf $TARBALL ;then
		true
	else
		echo "Failed to extract $TARBALL"
		exit
	fi

	if cd $APACHE_SRC_DIR ;then
		true
	else
		echo "Failed to chdir to $APACHE_SRC_DIR"
		exit
	fi

	CC=gcc ./configure \
		--prefix=$APACHE_INST_DIR \
		--with-mpm=worker \
		--with-program-name=httpd \
		--enable-http \
		--enable-so \
		--enable-authn-dbm=shared \
		--enable-authz-dbm=shared \
		--enable-deflate=shared \
		--enable-mime-magic=shared \
		--enable-expires=shared \
		--enable-headers=shared \
		--enable-proxy=shared \
		--enable-ssl=shared \
		--enable-info=shared \
		--enable-dav=shared \
		--enable-dav-fs=shared \
		--enable-dav-lock=shared \
		--enable-rewrite=shared \
		--enable-authn-file=shared \
		--enable-authz-host=shared \
		--enable-authz-groupfile=shared \
		--enable-authz-user=shared \
		--enable-auth-basic=shared \
		--enable-filter=shared \
		--enable-log-config=shared \
		--enable-env=shared \
		--enable-setenvif=shared \
		--enable-mime=shared \
		--enable-status=shared \
		--enable-dir=shared \
		--enable-actions=shared \
		--enable-alias=shared \
		--enable-authn-default=shared \
		--enable-authz-default=shared \
		--enable-mod-cache=shared \
		--enable-mod-mem-cache=shared \
		--enable-mod-disk-cache=shared \
		--enable-cgi=shared \
		--enable-include=shared \
		--enable-autoindex=shared \
		--enable-asis=shared \
		--disable-cgid \
		--disable-negotiation \
		--disable-userdir \
		&& make && make install
else
	echo "Apache $APACHEVER is already built; skipping ..."
	sleep 1
fi

if ! [ -d $APACHE_INST_DIR ]; then
	echo; echo "Failed to build Apache $APACHEVER for some reason"; echo
	exit
fi



# Build mod_perl 2.0
cd $SRC
TARBALL=mod_perl-$MODPERLVER.tar.gz

if ! [ -f $APACHE_INST_DIR/modules/mod_perl.so ]; then
	if ! [ -f $TARBALL ]; then
		URL=http://perl.apache.org/dist/$TARBALL
		wget $URL
		if ! [ -f $TARBALL ]; then
			echo "Failed to download $TARBALL from $URL"
			exit
		fi
	fi

	MODPERL_SRC_DIR=`find_extract_dir $TARBALL`
	if [ -d $MODPERL_SRC_DIR ]; then
		echo "rm -Rf $MODPERL_SRC_DIR"
		sleep 3
		rm -Rf $MODPERL_SRC_DIR
	fi

	if ! tar -zxf $TARBALL ;then
		echo "Failed to extract $TARALL"
		exit
	fi

	if ! cd $MODPERL_SRC_DIR ;then
		echo "Failed to chdir to $MODPERL_SRC_DIR"
		exit
	fi

	$PERL_INST_DIR/bin/perl Makefile.PL \
		MP_APXS=$APACHE_INST_DIR/bin/apxs \
		&& make && make install
else
	echo "mod_perl $MODPERLVER is already built; skipping ..."
	sleep 1
fi

if ! [ -f $APACHE_INST_DIR/modules/mod_perl.so ]; then
	echo; echo "Failed to build mod_perl $MODPERLVER for some reason"; echo
	exit
fi



# libapreq2
$PERL_INST_DIR/bin/cpan ExtUtils::XSBuilder::ParseSource
cd $SRC
URL=http://search.cpan.org`wget -q -O - http://search.cpan.org/~joesuf/libapreq2/ | grep Download | egrep -o "/CPAN/authors/.*.tar.gz"`
TARBALL=`echo $URL | sed 's/.*\///g'`
if ! [ -f $TARBALL ]; then
	wget $URL
	if ! [ -f $TARBALL ]; then
		echo "Failed to download $TARBALL from $URL"
		exit
	fi
fi

LIBAPREQ2_SRC_DIR=`find_extract_dir $TARBALL`

if ! [ -d $LIBAPREQ2_SRC_DIR ]; then
	if ! tar -zxf $TARBALL ;then
		echo "Failed to extract $TARALL"
		exit
	fi

	if ! cd $LIBAPREQ2_SRC_DIR ;then
		echo "Failed to chdir to $LIBAPREQ2_SRC_DIR"
		exit
	fi

	$PERL_INST_DIR/bin/perl Makefile.PL && make && make install
else
	echo "libapreq may already be built; skipping ..."
	sleep 1
fi


 

echo
echo "Complete."
echo



