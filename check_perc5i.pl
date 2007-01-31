#!/usr/bin/perl
############################################################
#
#   $Id: check_perc5i.pl 866 2006-12-24 17:02:07Z nicolaw $
#   check_perc5i.pl - Nagios plugin for PERC5/i RAID controllers using MegaCli
#
#   Copyright 2006,2007 Nicola Worthington
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

use 5.0.4;
use strict;
use vars qw($VERSION);

%ENV = ( PATH => '/bin:/usr/bin:/sbin:/usr/sbin' );
$VERSION = '0.02' || sprintf('%d', q$Revision: 809 $ =~ /(\d+)/g);

# Try and run the MegaCli command
my $raw = '';
eval { $raw = `MegaCli -AdpAllInfo -aAll 2>&1` || ''; };
status(3,"Error while executing MegaCli command: $raw $@") if $? || $@;

# Parse the key value pairs from the MegaCli output
my %data;
for (split(/\n/,$raw)) {
	if (my ($k,$v) = $_ =~ /^\s*([a-z\s]+?)\s+:\s*(\d+)\s*$/i) {
		$k =~ s/\s+//g;
		$data{$k} = $v;
	}
}

# Define a list of keys that we should have to diangose with
my @keys = qw(VirtualDrives Degraded Offline PhysicalDevices Disks
			CriticalDisks FailedDisks MemoryCorrectableErrors
			MemoryUncorrectableErrors);

# Complain if we don't have all the necessary keys
my @missing_keys = ();
for (@keys) { push @missing_keys, $_ unless exists $data{$_}; }
status(3,"Missing MegaCli keys: ". join(', ',@missing_keys)) if @missing_keys;

# Build a status summary message of the key value pairs
my $msg = join(', ', map { "$_=$data{$_}" } @keys);

# Critical if there are knackered disks
if ($data{$_} =~ /^[0-9\.]+$/ &&
		grep($data{$_} > 0, qw(Degraded Offline CriticalDisks FailedDisks))) {
	status(2,$msg);

# Warning if there are errors
} elsif ($data{$_} =~ /^[0-9\.]+$/ &&
		grep($data{$_} > 0, qw(MemoryCorrectableErrors MemoryUncorrectableErrors))) {
	status(1,$msg);

# Unknown if we don't appear to have at least 2 disks
} elsif ($data{$_} =~ /^[0-9\.]+$/ &&
		grep($data{$_} < 2, qw(Disks PhysicalDevices))) {
	status(3,$msg);

# Seems to be okay
} else {
	status(0,$msg);
}

sub status {
	my ($rtn,$msg) = @_;
	my @labels = qw(OK WARNING CRITICAL UNKNOWN);
	$msg =~ s/[\r\n]+/ /msg;
	$msg =~ s/\s+$//;
	print "$labels[$rtn] - $msg\n";
	exit $rtn;
}

__END__

