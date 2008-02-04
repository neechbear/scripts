#!/bin/bash

SERIAL=`dmidecode | egrep -A 10 "Chassis Information" | grep "Serial Number:" | sed 's/\s//g' | cut -d':' -f2`
LOGFILE="/var/tmp/$SERIAL.txt"

dmidecode | grep -A 9 "System Information" | egrep "(Manufacturer|Product Name|Serial Number|UUID):" | sed 's/^\s*//' > $LOGFILE

echo >> $LOGFILE
echo >> $LOGFILE
echo "- Controller information" >> $LOGFILE

MegaCli -AdpAllInfo -aALL >> $LOGFILE
MegaCli -CfgDsply -aALL >> $LOGFILE
MegaCli -AdpEventLog -GetEvents -f events.log -aALL && cat events.log >> $LOGFILE

echo >> $LOGFILE
echo >> $LOGFILE
echo "- Enclosure information" >> $LOGFILE

MegaCli -EncInfo -aALL >> $LOGFILE

echo "- Virtual drive information" >> $LOGFILE
echo >> $LOGFILE
echo >> $LOGFILE

MegaCli -LDInfo -Lall -aALL >> $LOGFILE

echo >> $LOGFILE
echo >> $LOGFILE
echo "- Physical drive information" >> $LOGFILE

MegaCli -PDList -aALL >> $LOGFILE
#MegaCli -PDInfo -PhysDrv [E:S] -aALL >> $LOGFILE

echo >> $LOGFILE
echo >> $LOGFILE
echo "- Battery backup information" >> $LOGFILE

MegaCli -AdpBbuCmd -aALL >> $LOGFILE

echo "Created $LOGFILE."

