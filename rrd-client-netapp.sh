#!/bin/bash

if test -z "$1"; then
	echo "Syntax: $0 <hostname>"
	exit 1
fi

HOST=$1
RRD_SERVER_CMD=/home/rrd/bin/rrd-server.pl

SNMP_MIB=NETWORK-APPLIANCE-MIB
SNMP_COMMUNITY=public
SNMP_VERSION=1
SNMP_TIMEOUT=10
SNMP_GETCMD="snmpget -t $SNMP_TIMEOUT -v$SNMP_VERSION -c $SNMP_COMMUNITY -m ALL -O qvU $HOST"

Timestamp=`date +"%s"`
TempFile=/tmp/rrd-netapp-snap.$$
rm -f $TempFile >/dev/null 2>&1

cpuBusyTimePerCent=`$SNMP_GETCMD $SNMP_MIB::cpuBusyTimePerCent.0`
cpuIdleTimePerCent=`$SNMP_GETCMD $SNMP_MIB::cpuIdleTimePerCent.0`
echo "$Timestamp.cpu.utilisation.System $cpuBusyTimePerCent" >> $TempFile
echo "$Timestamp.cpu.utilisation.Idle $cpuIdleTimePerCent" >> $TempFile
echo "$Timestamp.cpu.utilisation.IO_Wait 0" >> $TempFile
echo "$Timestamp.cpu.utilisation.User 0" >> $TempFile

miscNfsOps=`$SNMP_GETCMD $SNMP_MIB::miscNfsOps.0`
echo "$Timestamp.net.nfs.operations.NfsOps $miscNfsOps" >> $TempFile

Index=1
while $SNMP_GETCMD $SNMP_MIB::snapmirrorIndex.$Index >/dev/null 2>&1
do
	let "Index++"
done
let "Indexes = Index - 1"
# echo "$Indexes snapmirrors configured."

(
	for Index in `seq 1 $Indexes`
	do
		Src=`$SNMP_GETCMD $SNMP_MIB::snapmirrorSrc.$Index`
		LastTransMBs=`$SNMP_GETCMD $SNMP_MIB::snapmirrorLastTransMBs.$Index`
		# Status=`$SNMP_GETCMD $SNMP_MIB::snapmirrorStatus.$Index`
		# Dst=`$SNMP_GETCMD $SNMP_MIB::snapmirrorDst.$Index`
		# Lag=`$SNMP_GETCMD $SNMP_MIB::snapmirrorLag.$Index`
		# MirrorTimestamp=`$SNMP_GETCMD $SNMP_MIB::snapmirrorMirrorTimestamp.$Index`
		# LastTransTimeSeconds=`$SNMP_GETCMD $SNMP_MIB::snapmirrorLastTransTimeSeconds.$Index`

		Prefix=$Timestamp.misc.netapp.snapmirror.transfer
		SrcLabel=`echo $Src | sed -e 's/.*://; s/[^a-zA-Z0-9_]//g;'`
		let "LastTransBytes = LastTransMBs * 1024 * 1024"
		echo "$Prefix.$SrcLabel $LastTransBytes"
	done
) >> $TempFile

Index=1
while $SNMP_GETCMD $SNMP_MIB::dfIndex.$Index >/dev/null 2>&1
do
	let "Index++"
done
let "Indexes = Index - 1"
# echo "$Indexes filesystems configured."

(
	for Index in `seq 1 $Indexes`
	do
		dfFileSys=`$SNMP_GETCMD $SNMP_MIB::dfFileSys.$Index`
		dfPerCentKBytesCapacity=`$SNMP_GETCMD $SNMP_MIB::dfPerCentKBytesCapacity.$Index`
		dfPerCentInodeCapacity=`$SNMP_GETCMD $SNMP_MIB::dfPerCentInodeCapacity.$Index`

		if echo "$dfFileSys" | egrep "^\"?/vol/" >/dev/null 2>&1
		then
			Prefix=$Timestamp.hdd.capacity
			dfFileSys=`echo $dfFileSys | sed -e 's/"//g; s/^\/vol\///; s/[^a-zA-Z0-9_]/_/g; s/__/_/g; s/_$//;'`
			echo "$Prefix.$dfFileSys $dfPerCentKBytesCapacity"
			echo "$Prefix.inodes.$dfFileSys $dfPerCentInodeCapacity"
		fi
	done
) >> $TempFile

cat $TempFile | $RRD_SERVER_CMD -u $HOST
#cat $TempFile
rm -f $TempFile

exit

# NETWORK-APPLIANCE-MIB::dfIndex.1 = INTEGER: 1
# NETWORK-APPLIANCE-MIB::dfFileSys.1 = STRING: "vmaggr"
# NETWORK-APPLIANCE-MIB::dfKBytesTotal.1 = INTEGER: -1401748464
# NETWORK-APPLIANCE-MIB::dfKBytesUsed.1 = INTEGER: -1076333444
# NETWORK-APPLIANCE-MIB::dfKBytesAvail.1 = INTEGER: -325415020
# NETWORK-APPLIANCE-MIB::dfPerCentKBytesCapacity.1 = INTEGER: 28
# NETWORK-APPLIANCE-MIB::dfInodesUsed.1 = INTEGER: 121
# NETWORK-APPLIANCE-MIB::dfInodesFree.1 = INTEGER: 31021
# NETWORK-APPLIANCE-MIB::dfPerCentInodeCapacity.1 = INTEGER: 0
# NETWORK-APPLIANCE-MIB::dfMountedOn.1 = STRING: "vmaggr"
# NETWORK-APPLIANCE-MIB::dfMaxFilesAvail.1 = INTEGER: 31142
# NETWORK-APPLIANCE-MIB::dfMaxFilesUsed.1 = INTEGER: 121
# NETWORK-APPLIANCE-MIB::dfMaxFilesPossible.1 = INTEGER: 2040109444
# NETWORK-APPLIANCE-MIB::dfHighTotalKBytes.1 = INTEGER: 2
# NETWORK-APPLIANCE-MIB::dfLowTotalKBytes.1 = INTEGER: -1401748464
# NETWORK-APPLIANCE-MIB::dfHighUsedKBytes.1 = INTEGER: 0
# NETWORK-APPLIANCE-MIB::dfLowUsedKBytes.1 = INTEGER: -1076333444
# NETWORK-APPLIANCE-MIB::dfHighAvailKBytes.1 = INTEGER: 1
# NETWORK-APPLIANCE-MIB::dfLowAvailKBytes.1 = INTEGER: -325415020
# NETWORK-APPLIANCE-MIB::dfStatus.1 = INTEGER: mounted(2)
# NETWORK-APPLIANCE-MIB::dfMirrorStatus.1 = INTEGER: unmirrored(5)
# NETWORK-APPLIANCE-MIB::dfPlexCount.1 = INTEGER: 1
# NETWORK-APPLIANCE-MIB::dfType.1 = INTEGER: aggregate(3)
# NETWORK-APPLIANCE-MIB::dfHighSisSharedKBytes.1 = INTEGER: 0
# NETWORK-APPLIANCE-MIB::dfLowSisSharedKBytes.1 = INTEGER: 0
# NETWORK-APPLIANCE-MIB::dfHighSisSavedKBytes.1 = INTEGER: 0
# NETWORK-APPLIANCE-MIB::dfLowSisSavedKBytes.1 = INTEGER: 0
# NETWORK-APPLIANCE-MIB::dfPerCentSaved.1 = INTEGER: 0



# NETWORK-APPLIANCE-MIB::snapmirrorIndex.1 = INTEGER: 1
# NETWORK-APPLIANCE-MIB::snapmirrorSrc.1 = STRING: "aylvstore1:isovol"
# NETWORK-APPLIANCE-MIB::snapmirrorDst.1 = STRING: "vstore2:isovol"
# NETWORK-APPLIANCE-MIB::snapmirrorStatus.1 = INTEGER: idle(1)
# NETWORK-APPLIANCE-MIB::snapmirrorState.1 = INTEGER: source(5)
# NETWORK-APPLIANCE-MIB::snapmirrorLag.1 = Timeticks: (157400) 0:26:14.00
# NETWORK-APPLIANCE-MIB::snapmirrorTotalSuccesses.1 = Counter32: 355
# NETWORK-APPLIANCE-MIB::snapmirrorTotalRestartSuccesses.1 = Counter32: 1
# NETWORK-APPLIANCE-MIB::snapmirrorTotalFailures.1 = Counter32: 1
# NETWORK-APPLIANCE-MIB::snapmirrorTotalDeferments.1 = Counter32: 0
# NETWORK-APPLIANCE-MIB::snapmirrorTotalTransMBs.1 = Counter32: 78270
# NETWORK-APPLIANCE-MIB::snapmirrorTotalTransTimeSeconds.1 = Counter32: 4649
# NETWORK-APPLIANCE-MIB::snapmirrorThrottleValue.1 = INTEGER: 0
# NETWORK-APPLIANCE-MIB::snapmirrorMirrorTimestamp.1 = STRING: "Mon Apr 21 16:05:05 BST 2008"
# NETWORK-APPLIANCE-MIB::snapmirrorBaseSnapshot.1 = STRING: "vstore2(0101204315)_isovol.343"
# NETWORK-APPLIANCE-MIB::snapmirrorLastTransType.1 = STRING: "-"
# NETWORK-APPLIANCE-MIB::snapmirrorLastTransMBs.1 = Counter32: 0
# NETWORK-APPLIANCE-MIB::snapmirrorLastTransTimeSeconds.1 = Counter32: 11
# NETWORK-APPLIANCE-MIB::snapmirrorSchedule.1 = STRING: "- - - -"
# NETWORK-APPLIANCE-MIB::snapmirrorScheduleDesc.1 = STRING: "never"
# NETWORK-APPLIANCE-MIB::snapmirrorArguments.1 = ""
# NETWORK-APPLIANCE-MIB::snapmirrorSyncToAsync.1 = Counter32: 0

