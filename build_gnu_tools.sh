#!/bin/sh

# $Id: build_gnu_tools.sh,v 1.2 2005/04/30 17:27:59 nicolaw Exp $
# $Author: nicolaw $

##########################################
# Script configuration
#

BUILDDIR=$HOME/build/gnu
PREFIX=$HOME/gnu/`uname -si | sed 's/ /-/g'`
SOURCEURL=ftp://gnu.teleglobe.net/ftp.gnu.org



##########################################
# Create installation prefix directories
#

if ! [ -d $BUILDDIR ]; then
	mkdir -p $BUILDDIR
fi
if ! [ -d $PREFIX ]; then
	mkdir -p $PREFIX
fi
if ! [ -d $PREFIX/bin ]; then
	mkdir $PREFIX/bin
fi



##########################################
# Define list of packages to build
#

cd $BUILDDIR
links -dump $SOURCEURL | grep utils | cut -b53- > packages
for i in bash bc wget which units tar nano screen sed less jwhois grep gzip finger cpio
do
	echo $i >> packages
done
sort -o packages packages



##########################################
# Build and install each package
#

for package in `cat packages`
do
	if ! [ -d $package ]; then
		echo "Setting up $package ..."
		mkdir $package
	fi

	# Mirror
	if [ -d $package ]; then
		echo "Mirroring $package ..."
		cd $package
		wget -q -nH -m -nd $SOURCEURL/$package/

		# Extract
		echo "Extracting $tarball ..."
		tarball=`ls *.tar.gz | grep -E "^$package-[0-9]" | sort -n | tail -n 1`
		builddir=`echo $tarball | sed 's/\.tar\.gz//'`
		if [ -d $builddir ]; then
			rm -Rf $builddir
		fi
		gzip -cd $tarball | tar x

		# Build
		if [ -d $builddir ]; then
			echo "Building $tarball ..."
			cd $builddir
			./configure --prefix=$PREFIX/$builddir --quiet
			make > /dev/null

			# Install
			echo "Installing $package ..."
			make install > /dev/null

			# Symlink
			cd $PREFIX
			echo "Symlinking $package ..."
			if [ -L $package ]; then
				rm $package
			fi
			ln -s $builddir $package
			if [ -d $package/bin ]; then
				cd $package/bin
				for file in *
				do
					cd $PREFIX/bin
					if [ -L $file ]; then
						rm $file
					fi
					ln -s ../$package/bin/$file $file
				done
			fi
		fi
	fi

	echo
	cd $BUILDDIR
done


