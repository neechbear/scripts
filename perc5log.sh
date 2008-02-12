#!/bin/bash

SERIAL=`dmidecode | egrep -A 10 "Chassis Information" | grep "Serial Number:" | sed 's/\s//g' | cut -d':' -f2`
LOGFILE="/var/tmp/$SERIAL.txt"

dmidecode | grep -A 9 "System Information" | egrep "(Manufacturer|Product Name|Serial Number|UUID):" | sed 's/^\s*//' > $LOGFILE

echo >> $LOGFILE
echo >> $LOGFILE
echo "-------------------------------------------------------------------------------" >> $LOGFILE
echo "- Controller information" >> $LOGFILE
MegaCli -AdpAllInfo -aALL >> $LOGFILE
MegaCli -CfgDsply -aALL >> $LOGFILE

echo >> $LOGFILE
echo >> $LOGFILE
echo "-------------------------------------------------------------------------------" >> $LOGFILE
echo "- Enclosure information" >> $LOGFILE
MegaCli -EncInfo -aALL >> $LOGFILE

echo >> $LOGFILE
echo >> $LOGFILE
echo "-------------------------------------------------------------------------------" >> $LOGFILE
echo "- Virtual drive information" >> $LOGFILE
MegaCli -LDInfo -Lall -aALL >> $LOGFILE

echo >> $LOGFILE
echo >> $LOGFILE
echo "-------------------------------------------------------------------------------" >> $LOGFILE
echo "- Physical drive information" >> $LOGFILE
MegaCli -PDList -aALL >> $LOGFILE

for i in `MegaCli -PDList -aALL  | perl -ne 'if (/^(Enclosure|Slot)\s+Number:\s+([0-9]{1,2})\s*$/) { if (substr($1,0,1) eq "E") { $E = $2; } else { print "[$E:$2]\n"; } }'`
do
	echo >> $LOGFILE
	echo >> $LOGFILE
	echo "-------------------------------------------------------------------------------" >> $LOGFILE
	echo "- Physical drive information $i" >> $LOGFILE
	MegaCli -PDInfo -PhysDrv $i -aAll >> $LOGFILE
done

echo >> $LOGFILE
echo >> $LOGFILE
echo "-------------------------------------------------------------------------------" >> $LOGFILE
echo "- Battery backup information" >> $LOGFILE
MegaCli -AdpBbuCmd -aALL >> $LOGFILE


echo >> $LOGFILE
echo >> $LOGFILE
echo "-------------------------------------------------------------------------------" >> $LOGFILE
echo "- Controller event log" >> $LOGFILE
MegaCli -AdpEventLog -GetEvents -f events.log -aALL && cat events.log >> $LOGFILE

echo "Created $LOGFILE."

