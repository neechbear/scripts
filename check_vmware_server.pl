#!/usr/bin/perl -w
# vim:ts=4:sw=4:tw=78
# See VmPerl and lib/SampleScripts (stats.pl and vmware-cmd)
# Written by Nicola Worthington (2007)

BEGIN {
	if ($^O eq 'MSWin32') {
		my $ProgramFiles = defined $ENV{ProgramFiles} && -d $ENV{ProgramFiles}
			? $ENV{ProgramFiles}
			: defined $ENV{SystemDrive} && -d "$ENV{SystemDrive}\\Program Files"
				? "$ENV{SystemDrive}\\Program Files"
				: 'C:\Program Files';
		my $VmPerl = 'VMware\VMware VmPerl Scripting API\perl5\site_perl\5.005';
		push @INC, sprintf('%s\%s', $ProgramFiles, $VmPerl);
		push @INC, sprintf('%s\%s\MSWin32-x86', $ProgramFiles, $VmPerl);
	}
}

use 5.6.1;
use strict;
use warnings;
use Getopt::Std qw();
use File::Basename qw(basename);
use Data::Dumper qw(Dumper);

require VMware::VmPerl;
import VMware::VmPerl;
require VMware::VmPerl::Server;
require VMware::VmPerl::VM;
require VMware::VmPerl::ConnectParams;
require VMware::VmPerl::Question;

# Define the usual suspects
our $VERSION = '0.01';
(our $SELF = $0) =~ s/.*\///;
our @NAGIOS_RTN = qw(OK WARNING CRITICAL UNKNOWN);

# Parse command line options
my $opts = {
		H => 'vm1',
		U => 'vmware',
		P => 'password',	
		p => 902,
	};
Getopt::Std::getopts('vhqVH:U:P:p:c:', $opts);
display_help(), exit if exists $opts->{h};
display_version(), exit if exists $opts->{v};

# Set default return code
my $rtn = 0;

# Connect to VMware server
my $cp = get_cp($opts->{H}, $opts->{p}, $opts->{U}, $opts->{P});
my $vms = connect_to_vms($cp);
my @cfgs = defined $opts->{c} ? ($opts->{c}) : get_registered_vm_names($vms);

# Build a list of metrics for each guest vm
my %status;
for my $cfg (@cfgs) {
	my $vm = connect_to_vm($cp, $cfg);
	my ($state,$state_str) = get_vm_state($vm);	

	$status{basename($cfg)}->{state} = $state_str;
	$rtn = 2 unless $state == 1;
}

# Build a nagios status string
my @msg;
while (my ($cfg, $metrics) = each %status) {
	my @metrics;
	while (my ($metric, $value) = each %{$metrics}) {
		push @metrics, "$metric=$value";
	}
	push @msg, "$cfg ". join(',',@metrics);
}

# Print status and exit
nagios_response($rtn, join(', ', @msg));

exit;


sub display_help {
	display_version();
	print qq{Syntax: $SELF [[-v|-h] [-H <host>] [-U <user>] [-P <password>] [-p <port>]]
        -v            Display version information
        -h            Display this help information
        -H <host>     Define the VMware server host to connect to
        -U <user>     Define the username to connect to the server as
        -P <pass>     Define the password to connect to the server with
        -p <port>     Define the TCP port the server is listening on
};
}


sub display_version {
	print "$SELF version $VERSION\n";
}


sub get_registered_vm_names {
	my $vms = shift;

	my @list = $vms->registered_vm_names();
	if (!@list) { 
		my ($err, $errstr) = $vms->get_last_error();
		if ($err != 0) { 
			undef $vms;
			nagios_response(3, "VMControl error $err: $errstr");
		}
	}

	return @list;
}


sub nagios_response {
	my ($rtn,$msg) = @_;

	$rtn = 3 unless defined $rtn || defined $NAGIOS_RTN[$rtn];
	$msg = 'Unknown state' unless defined $msg && $msg =~ /\S+/;
	$msg =~ s/[\r\n]+/ /g;

	print "$NAGIOS_RTN[$rtn] - $msg\n";
	exit $rtn;
}


sub get_cp {
	my ($host, $port, $user, $pass) = @_;
    my $cp = &VMware::VmPerl::ConnectParams::new($host, $port, $user, $pass);
    return $cp;
}


sub get_vms {
	my $vms = &VMware::VmPerl::Server::new();
	return $vms;
}


sub connect_to_vm {
	my ($cp,$cfg) = @_;

	my $vm = VMware::VmPerl::VM::new();
	if (!$vm->connect($cp, $cfg)) {
	my ($error_number, $error_string) = $vm->get_last_error();
		nagios_response(2, "Could not connect to vm: Error $error_number: $error_string\n");
	}

	return $vm;
}


sub connect_to_vms {
	my $cp = shift;

	my $vms = get_vms();
	if (!$vms || !$vms->connect($cp)) {
		my ($err, $errstr) = $vms->get_last_error();
		nagios_response(2, "Could not connect to vmware-authd (VMControl error $err: $errstr)");
	}

	return $vms;
}


sub get_vm_state {
	my $vm = shift;

	my $cur_state = $vm->get_execution_state();
	if (!defined($cur_state)) {
		my ($error_number, $error_string) = $vm->get_last_error();
		nagios_response(2, "Could not get execution state: Error $error_number: $error_string");
	}

	return ($cur_state,constant_map('VM_EXECUTION_STATE', $cur_state));
}


sub vm_constant {
	my $constant_str = shift;
	return VMware::VmPerl::constant($constant_str, 0);
}


sub constant_map {
	my ($constant,$value) = @_;
	return unless defined $constant && defined $value;

	my %constant_map = (
		'VM_EXECUTION_STATE' => {
			'1' => 'on',
			'2' => 'off',
			'3' => 'suspended',
			'4' => 'stuck',
			'5' => 'unknown',
		},
		'VM_TIMEOUT_ID' => {
			'default' => '1',
		},
		'VM_PRODUCT' => {
			'1' => 'ws',
			'2' => 'gsx',
			'3' => 'esx',
			'4' => 'unknown',
		},
		'VM_PLATFORM' => {
			'1' => 'windows',
			'2' => 'linux',
			'3' => 'vmnix',
			'4' => 'unknown',
		},
		'VM_POWEROP_MODE' => {
			'hard' => '1',
			'soft' => '2',
			'trysoft' => '3',
		},
		'VM_PRODINFO' => {
			'product' => '1',
			'platform' => '2',
			'build' => '3',
			'majorversion' => '4',
			'minorversion' => '5',
			'revision' => '6',
		},
	);

	my $str = $constant_map{$constant}->{$value} || '';
	return sprintf('[%s]:%s', $value, $str);
}


__END__


