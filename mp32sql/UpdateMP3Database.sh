#!/bin/bash

PATH=$PATH:/home/nicolaw/bin
WEBROOT=$HOME/webroot
WWW=$WEBROOT/www

# Nuke the old database
mysql nicolaw -e'delete from mp3;'

# Rebuild the database from the filesystem
mp32sql.pl -D nicolaw -u nicolaw -p nicolaw -d /mp3

# Nuke the old playlists
rm -f $WWW/playlists/*.m3u

# Create a new set of playlists
sql2m3u.pl -D nicolaw -u nicolaw -p nicolaw -d $WWW/playlists

