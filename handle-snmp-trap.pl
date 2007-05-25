#!/usr/bin/perl -w
############################################################
#
#   $Id: handle-snmp-trap.pl 968 2007-03-03 22:04:15Z nicolaw $
#   handle-snmp-trap.pl - Parse SNMP Traps from snmptrapd to Nagios
#
#   Copyright 2007 Nicola Worthington
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

use 5.6.1;
use strict;
use warnings;
use SNMP::Trapinfo qw();
use Sys::Syslog;

use constant NAGIOS_CMD_FILE => '/home/nagios/var/rw/nagios.cmd';
use constant NAGIOS_SERVICE  => 'Dell OpenManage';
use constant PROCESS_SERVICE_CHECK_RESULT => "[%d] PROCESS_SERVICE_CHECK_RESULT;%s;%s;%s;%s\n";

my @NAGIOS_CODES = qw(OK WARNING CRITICAL UNKONWN);
(my $SELF = $0) =~ s/.*\///;

openlog($SELF, 'cons,pid', 'local3');

my $alert = load_Configuration();
my $trap = SNMP::Trapinfo->new(*STDIN);
my ($mib,$trapid) = $trap->trapname =~ /(.+)\.([0-9]+)$/;

syslog('info', 'hostname=[%s] hostip=[%s] trapname=[%s] sysUpTime=[%s] mib=[%s] trapid=[%s]',
		$trap->hostname,
		$trap->hostip,
		$trap->trapname,
		$trap->expand('${SNMPv2-MIB::sysUpTime}'),
		$mib,
		$trapid,
	);

if (exists $alert->{$mib}->{$trapid}->[0]) {
	my $msg = "[$trapid] $alert->{$mib}->{$trapid}->[1]";
	submit_Passive_Nagios_Check(NAGIOS_CMD_FILE,
			$trap->hostname,
			$alert->{$mib}->{$trapid}->[0],
			$msg,
		);
} else {
	submit_Passive_Nagios_Check(NAGIOS_CMD_FILE,
			$trap->hostname,
			3,
			$trap->trapname,
		);
}

closelog();
exit;

sub parse_sysUpTime {
	my $str = shift || '00:00:00:00.00';
	my $seconds = 0;
	if (my ($day,$hour,$min,$sec) = $str =~ /^\d\d:\d\d:\d\d:\d\d\.\d\d$/) {
		$seconds = $sec;
		$seconds += ($min * 60);
		$seconds += ($hour * 60 * 60);
		$seconds += ($day * 60 * 60 * 24);
	}
	return $seconds;
}

sub submit_Passive_Nagios_Check {
	my ($file,$hostname,$status,$msg) = @_;

	open(FH, '>>', $file) || die "Unable to open file handle FH for file '$file': $!";
	printf(FH PROCESS_SERVICE_CHECK_RESULT,
			time,
			$hostname,
			NAGIOS_SERVICE,
			$status,
			$msg,
		);
	close(FH) || warn "Unable to close file handle FH for file '$file': $!";

	syslog('info', '%s - %s',
			$NAGIOS_CODES[$status],
			$msg,
		);
}

sub load_Configuration {
	my %alert;
	my $mib = '';
	while (local $_ = <DATA>) {
		chomp;
		next unless /\S/;
		next if /^\s*[#;]/;
		if (/^(\S+)/) {
			$mib = $1;
		} elsif (/^\s+(.+?)\s*$/) {
			my ($trapid, $status, $msg) = split(/\s+/,$1,3);
			$alert{$mib}->{$trapid} = [($status,$msg)];
		}
	}
	return \%alert;
}

__END__

# http://support.dell.com/support/edocs/software/svradmin/5.1/en/snmp/html/snmpc25.htm#wp1060992
# http://www.oidview.com/mibs/674/MIB-Dell-10892.html
# http://www.assure24.com/product/2673-snmp-mibs-download.htm
# http://www.nagiosexchange.org/DELL_Server.61.0.html?&tx_netnagext_pi1%5Bp_view%5D=8

#############################
# /etc/snmp/snmptrapd.conf
# ignoreAuthFailure yes
# traphandle default /home/nagios/libexec/handle-snmp-trap.pl
#############################

#############################
# /home/nagios/etc/services/openmanage-snmp.cfg
# define service {
#         use                             generic-service
#         name                            openmanage-snmp-service
#         service_description             Dell OpenManage
#         is_volatile                     1
#         active_checks_enabled           0
#         check_period                    none
#         max_check_attempts              1
#         normal_check_interval           1
#         retry_check_interval            1
#         contact_groups                  ase-admins
#         notification_options            w,u,c,r
#         notification_interval           31536000
#         notification_period             24x7
#         check_command                   check_none
#         register                        0
# }
# 
# define service {
#         use             openmanage-snmp-service
#         hostgroup_name  dracs
# }
#############################

# BMC
SNMPv2-SMI::enterprises.3183.1.1.0
	262402	2	Generic Critical Fan Failure
	262530	0	Generic Critical Fan Failure Cleared
	131330	2	Under-Voltage Problem (Lower Critical - going low)
	131458	0	Under-Voltage Problem Cleared
	131841	2	Generic Critical Voltage Problem
	131840	0	Generic Critical Voltage Problem Cleared
	65792	1	Under-Temperature Warning (Lower non-critical, going low)
	65920	0	Under-Temperature Warning Cleared
	65794	2	Under-Temperature Problem (Lower Critical - going low)
	65922	0	Under-Temperature Problem Cleared
	65799	1	Over-Temperature warning (Upper non-critical, going high)
	65927	0	Over-Temperature warning Cleared
	65801	2	Over-Temperature Problem (Upper Critical - going high)
	65929	0	Over-Temperature Problem Cleared
	131328	1	Under-Voltage Warning (Lower Non Critical - going low)
	131456	0	Under-Voltage Warning Cleared
	131330	2	Under-Voltage Problem (Lower Critical - going low)
	131458	0	Under-Voltage Problem Cleared
	131335	1	Over-Voltage Warning (Upper Non Critical - going high)
	131463	0	Over-Voltage Warning Cleared
	131337	2	Over-Voltage Problem (Upper Critical - going high)
	131465	0	Over-Voltage Problem Cleared
	131841	2	Generic Critical Voltage Problem
	131840	0	Generic Critical Voltage Problem Cleared
	356096	2	Chassis Intrusion - Physical Security Violation
	356224	0	Chassis Intrusion (Physical Security Violation) Event Cleared
	262400	1	Generic Predictive Fan Failure (predictive failure asserted)
	262528	0	Generic Predictive Fan Failure Cleared
	262402	2	Generic Critical Fan Failure
	262530	0	Generic Critical Fan Failure Cleared
	264962	1	Fan redundancy has been degraded
	264961	2	Fan Redundancy Lost
	264960	0	Fan redundancy Has Returned to Normal
	2715392	1	Battery Low (Predictive Failure)
	2715520	0	Battery Low (Predictive Failure) Cleared
	2715393	2	Battery Failure
	2715521	0	Battery Failure Cleared
	487169	2	CPU Thermal Trip (Over Temperature Shutdown)
	487297	0	CPU Thermal Trip (Over Temperature Shutdown) Cleared
	487168	2	CPU Internal Error
	487296	0	CPU Internal Error Cleared
	487173	2	CPU Configuration Error
	487301	0	CPU Configuration Error Cleared
	487175	0	CPU Presence (Processor Presence detected)
	487303	2	CPU Not Present (Processor Not Present)
	487170	2	CPU BIST (Built In Self Test) Failure
	487298	0	CPU BIST (Built In Self Test) Failure Cleared
	487176	2	CPU Disabled (Processor Disabled)
	487304	0	CPU Enabled (Processor Enabled)
	487178	1	CPU Throttle (Processor Speed Reduced)
	487306	0	CPU Throttle Cleared (Normal Processor Speed)
	527106	1	Power Supply Redundancy Degraded
	527105	2	Power Supply Redundancy Lost
	527104	0	Power Supply Redundancy Has Returned to Normal
	552704	0	Power Supply Inserted
	552832	1	Power Supply Removed
	552705	2	Power Supply Failure
	552833	0	Power Supply Failure Cleared
	552706	1	Power Supply Warning
	552834	0	Power Supply Warning Cleared
	552707	2	Power Supply AC Lost
	552835	0	Power Supply AC Restored
	789249	2	Memory Redundancy Has Been Lost
	789248	0	Memory redundancy Has Returned to Normal
	1076994	0	System Event Log (SEL) Cleared
	1076996	2	System Event Log (SEL) Full (Logging Disabled)
	2322176	2	ASR (Automatic System Recovery) Timer Expired
	2322177	2	ASR (Automatic System Recovery) Reset Occurred
	2322178	2	ASR (Automatic System Recovery) Power Down Occurred
	2322179	2	ASR (Automatic System Recovery) Power Cycle Occurred
	
# RAC
SNMPv2-SMI::enterprises.674.10892.2.0
	1001	0	Test Message: TEST TRAP
	1002	1	RAC Authentication failures during a time period have exceeded a threshold. "RAC login failure caused by authentication failure, number of concurrent logins exceed limit, or permission denied."
	1003	2	The RAC cannot communicate with the baseboard management controller (ESM). RAC lost communication with ESM.
	1005	2	The RAC has detected a system power state change to powered-off. RAC detected a system power state change to power-off.
	1007	2	The RAC has detected that the system watchdog has expired indicating a system hang. RAC has detected the system watchdog expired (normally indicating a system hang).
	1008	1	The RAC Battery charge is below 25% indicating that the battery may only be able to power the DRSC for 8-10 minutes. RAC detected its battery charge is below 25% full.
	1010	1	The RAC Temperature probe has detected a Warning value. RAC temperature probe reading exceeded warning threshold.
	1011	2	The RAC Temperature probe has detected a failure (or critical) value. RAC temperature probe reading exceeded critical threshold.
	1013	1	The RAC voltage probe has detected a warning value. RAC voltage probe reading exceeded warning threshold.
	1014	2	The RAC voltage probe has detected a failure (or critical) value. RAC voltage probe reading exceeded critical threshold.
	1015	2	The RAC has detected a new event in the System Event Log with Severity: Warning. RAC detected a new system event log with warning severity (detailed log info is in drsAlert Message varbind).
	1016	2	The RAC has detected a new event in the System Event Log with Severity: Critical. RAC detected a new system event log with critical severity (detailed log info is in drsAlert Message varbind).
	1017	2	The RAC system event log is 80% full. RAC detected system event log is 80% full.
	1018	2	The RAC system event log is 90% full. RAC detected system event log is 90% full.
	1019	2	The RAC system event log is 100% full. RAC detected system event log is 100% full.
	1020	0	The RAC has detected a new event in the System Event Log with Severity: Normal. RAC detected a new system event log with normal severity (detailed log info is in drsAlert Message varbind).

# OpenManage?
SNMPv2-SMI::enterprises.674.10892.2.0
	1004	2	Thermal shutdown protection has been initiated
	1052	0	Temperature sensor returned to a normal value
	1053	1	Temperature sensor detected a warning value
	1054	2	Temperature sensor detected a failure value
	1055	2	Temperature sensor detected a non-recoverable value
	1102	0	Fan sensor returned to a normal value
	1103	1	Fan sensor detected a warning value
	1104	2	Fan sensor detected a failure value
	1105	2	Fan sensor detected a non-recoverable value
	1152	0	Voltage sensor returned to a normal value
	1153	1	Voltage sensor detected a warning value
	1154	2	Voltage sensor detected a failure value
	1155	2	Voltage sensor detected a non-recoverable value
	1202	0	Current sensor returned to a normal value
	1203	1	Current sensor detected a warning value
	1204	2	Current sensor detected a failure value
	1205	2	Current sensor detected a non-recoverable value
	1252	0	Chassis intrusion returned to a normal value
	1254	2	Chassis intrusion detected
	1304	0	Redundancy regained
	1305	1	Redundancy degraded
	1306	2	Redundancy lost
	1352	0	Power supply returned to a normal value
	1354	2	Power supply detected a failure
	1403	1	Memory device ECC Correctable error count crossed a warning threshold
	1404	2	Memory device ECC Correctable error count crossed a failure threshold
	1405	2	Memory device ECC Correctable error count crossed a non-recoverablethreshold
	1452	0	Fan enclosure inserted into system
	1453	2	Fan enclosure removed from system
	1454	2	Fan enclosure removed from system for an extended amount of time
	1501	2	Power cord is not being monitored
	1502	0	AC power has been restored
	1504	2	AC power has been lost

