#!/bin/bash

export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin

device=`mount | egrep "^/dev/disk[0-9].*\(.*?udf.*?\)" | cut -d' ' -f 1`
mnt=`mount | egrep "^/dev/disk[0-9].*\(.*?udf.*?\)" | cut -d' ' -f 3`
name=`echo "$mnt" | /usr/bin/sed -E 's/.*\///; s/[^A-Za-z0-9_-]//g;'` 

if [ "x$device" = "x" ] || [ "x$mnt" = "x" ]; then
	echo "No mounted DVD or CDROM was found; aborting!"
	drutil eject
	exit 1
fi

if [ "x$1" != "x" ]; then
	name=$1
fi

name=`echo "$name" | sed -E 's/^\s*//; s/\s*$//;'`
if ! `echo "$name" | egrep -i ".iso$" >/dev/null 2>&1`; then
	name="$name.iso"
fi

echo "Unmounting '$mnt' ..."
if ! umount "$mnt"; then
	echo "Failed to unmount '$mnt'; aborting!"
	exit 1
fi

echo "Dumping $device to '$name' ..."
dd if=$device of="$name"

ls -lh "$name"
drutil eject

