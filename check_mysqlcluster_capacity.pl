#!/usr/bin/perl -w
# vim:ts=4:sw=4:tw=78
# Written by Nicola Worthington (2007)

use constant MANAGEMENT_LOG_FILE      => '/var/lib/mysql-cluster/mgmt1/ndb_1_cluster.log';
use constant WARNING_AT_PERCENT_FREE  => 80;
use constant CRITICAL_AT_PERCENT_FREE => 90;
use constant BYTES_TO_READ_FROM_LOG   => -10240;
use constant SECONDS_BREFORE_STALE    => 60*10;

use 5.6.1;
use strict;
use warnings;
use Getopt::Std qw();
use File::Basename qw(basename);
use Data::Dumper qw(Dumper);

# Define the usual suspects
our $VERSION = '0.01';
(our $SELF = $0) =~ s/.*\///;
our @NAGIOS_RTN = qw(OK WARNING CRITICAL UNKNOWN);

# Parse command line options
my $opts = {
		l => MANAGEMENT_LOG_FILE,
		w => WARNING_AT_PERCENT_FREE,
		c => CRITICAL_AT_PERCENT_FREE,
	};
Getopt::Std::getopts('vhl:w:c:', $opts);
display_help(), exit if exists $opts->{h};
display_version(), exit if exists $opts->{v};

nagios_response(3, "Missing logfile '$opts->{l}'") unless -f $opts->{l};
nagios_response(3, "Unable to read logfile '$opts->{l}'") unless -r $opts->{l};
nagios_response(3, "Empty logfile '$opts->{l}'") unless -s $opts->{l};
nagios_response(3, "Empty logfile '$opts->{l}'") unless -s $opts->{l};

my $mtime = (stat($opts->{l}))[9];
my $age = time - $mtime;

my $rtn = 0;
my @msg;
my %nodes;
my %capacity;

open(LOG,'<',$opts->{l}) || nagios_respond(3, "Unable to open logfile '$opts->{l}': $!");
my $size = -s $opts->{l};
seek(LOG, BYTES_TO_READ_FROM_LOG, 2);
while (local $_ = <LOG>) {
	if (my ($node,$type,$capacity) = $_ =~ 
			/\bNode\s+([0-9]{1,2}):\s+(Data|Index)\s+usage\s+is\s+([0-9]{1,3})%/i) {
		$capacity{"Node${node}-${type}"} = $capacity;
		$nodes{$node} = 1;
	}
}
close(LOG);

$ENV{DEBUG} && warn Dumper(\%capacity);

while (my ($node,$capacity) = each %capacity) {
	push @msg, "${node}[$capacity\%]";
	$rtn = 1 if $rtn <= 1 && $capacity >= $opts->{w};
	$rtn = 2 if $rtn      && $capacity >= $opts->{c};
}

nagios_response(2, sprintf("Stale logfile '$opts->{l}' is $age seconds old.".
		' Checked %d nodes; %s',
		scalar(keys %nodes),
		join(', ', @msg))
	) if $age > SECONDS_BREFORE_STALE;

nagios_response($rtn, sprintf('Checked %d nodes; %s',
		scalar(keys %nodes),
		join(', ', @msg))
	);

exit;


sub nagios_response {
	my ($rtn,$msg) = @_;

	$rtn = 3 if !defined($rtn) || !defined($NAGIOS_RTN[$rtn]);
	$msg = '(No output)' unless defined $msg && $msg =~ /\S+/;
	$msg =~ s/[\r\n]+/ /g;

	print "$NAGIOS_RTN[$rtn] - $msg\n";
	exit $rtn;
}

sub display_help {
display_version();
print qq{Syntax: $SELF [[-v|-h] | [-l <logfile>] [-w <percent>] [-c <percent>]]
      -v            Display version information
      -h            Display this help information
      -l <logfile>  The location of the MySQL Cluster Management Node log file
      -w <percent>  Percentage free to set a warning alert
      -c <percent>  Percentage free to set a critical alert
};
}

sub display_version {
	print "$SELF version $VERSION\n";
}


__END__


