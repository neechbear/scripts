#!/usr/bin/perl -w

use 5.6.1;
use strict;
use warnings;
use Storable qw();
use Getopt::Std qw();
use Data::Dumper qw();
use Fcntl qw();
use Devel::Size qw();

BEGIN {
	use Cwd qw();
	use constant CWD => Cwd::cwd();
	use constant ARGV0 => $0;
	use constant ARGVN => @ARGV;
	use constant MAX_BYTES => 1024 * 1024; # 1MB
}

my $state_fh;
my $opts = {};
Getopt::Std::getopts('F:',$opts);

my $state = $opts->{F} ? load_state($opts->{F}) : { age => 0 };
print '$state ',Data::Dumper::Dumper($state);

INPUT: {
	$state->{input} ||= [()];
	local $| = 1;
	print "Give me some state information please: ";
	local $_ = <>; chomp;
	push @{$state->{input}}, $_ if /\S/;

	my $stuff = [];
	do {
		print '.';
		push @{$stuff}, 'X' x 102400;
		sleep 1;
	} while Devel::Size::total_size($stuff) <= MAX_BYTES;

	print "\nWe're using too much memory; respawning ...\n";
	eval { self_exec($state); };
	die "Bugger! $@" if $@; # Do something better
}

	print Devel::Size::total_size($state)."\n";
exit;

sub self_exec {
	my $state = shift;
	my $fileno = save_state($state);
	my @ARGV = ARGVN;
	shift(@ARGV),shift(@ARGV) if @ARGV >= 2 && $ARGV[0] eq '-F';
	chdir(CWD) || die sprintf("Unable to chdir to '%s': %s",CWD,$!);
	exec(ARGV0,'-F',$fileno,@ARGV) ||
		die sprintf("Unable to exec '%s': %s",join("','",ARGV0,@ARGV),$1);
}

sub save_state {
	my $state = shift;
	if (ref($state_fh) eq 'GLOB') {
		seek($state_fh,0,0);
		truncate($state_fh,0);
	} else {
		open($state_fh,'+>',undef) ||
			die "Unable to open anonymous state file handle: $!";
	}
	fcntl($state_fh, Fcntl::F_SETFD(), 0) ||
		die "Can't clear close-on-exec flag on temp fh: $!";
	Storable::store_fd($state,$state_fh);
	return fileno($state_fh);
}

sub load_state {
	my $fileno = shift;
	my $state = {};
	if (open($state_fh,'+<&=',$fileno)) {
		seek($state_fh,0,0);
		$state = Storable::fd_retrieve($state_fh);
		$state->{age}++;
	} else {
		warn "Unable to read state from fileno '$fileno': $!";
	}
	return $state;
}

__END__

