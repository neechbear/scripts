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

Index=1
while $SNMP_GETCMD $SNMP_MIB::snapmirrorIndex.$Index >/dev/null 2>&1
do
	let "Index++"
done
let "Indexes = Index - 1"
# echo "$Indexes snapshots configured."

TempFile=/tmp/rrd-netapp-snap.$$
(
	for Index in `seq 1 $Indexes`
	do
		Timestamp=`date +"%s"`
		Src=`$SNMP_GETCMD $SNMP_MIB::snapmirrorSrc.$Index`
		LastTransMBs=`$SNMP_GETCMD $SNMP_MIB::snapmirrorLastTransMBs.$Index`
		# Status=`$SNMP_GETCMD $SNMP_MIB::snapmirrorStatus.$Index`
		# Dst=`$SNMP_GETCMD $SNMP_MIB::snapmirrorDst.$Index`
		# Lag=`$SNMP_GETCMD $SNMP_MIB::snapmirrorLag.$Index`
		# MirrorTimestamp=`$SNMP_GETCMD $SNMP_MIB::snapmirrorMirrorTimestamp.$Index`
		# LastTransTimeSeconds=`$SNMP_GETCMD $SNMP_MIB::snapmirrorLastTransTimeSeconds.$Index`

		Prefix=$Timestamp.misc.netapp.snapshot.transfer
		SrcLabel=`echo $Src | sed -e 's/.*://; s/[^a-zA-Z0-9_]//g;'`
		let "LastTransBytes = LastTransMBs * 1024 * 1024"
		echo "$Prefix.$SrcLabel $LastTransBytes"
	done
) > $TempFile

cat $TempFile | $RRD_SERVER_CMD -u $HOST
# cat $TempFile
rm -f $TempFile

exit

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

