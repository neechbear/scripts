#!/usr/bin/perl -w

use 5.6.1;
use strict;
use warnings;
use Storable qw();
use Getopt::Std qw();
use Data::Dumper qw();
use Fcntl qw();

my $state_fh;
my $opts = {};
Getopt::Std::getopts('F:',$opts);

my $state = $opts->{F} ? load_state($opts->{F}) : {};
unless ($opts->{F}) {
	local $| = 1;
	print "Give me some state information please: ";
	$state->{input} = <>;
	chomp $state->{input};
	self_exec($state);
}

print '$state ',Data::Dumper::Dumper($state);
exit;

sub self_exec {
	my $state = shift;
	my $fileno = save_state($state);
	shift(@ARGV),shift(@ARGV) if @ARGV >= 2 && $ARGV[0] eq '-F';
	exec($0,'-F',$fileno,@ARGV);
}

sub save_state {
	my $state = shift;
	if (open($state_fh,'+>',undef)) {
		fcntl($state_fh, Fcntl::F_SETFD(), 0) ||
			warn "Can't clear close-on-exec flag on temp fh: $!";
		Storable::store_fd($state,$state_fh);
		return fileno($state_fh);
	}
}

sub load_state {
	my $fileno = shift;
	my $state = {};
	my $fh;
	if (open($fh,'+<&=',$fileno)) {
		seek($fh,0,0);
		$state = Storable::fd_retrieve($fh);
		close($fh);
	} else {
		warn "Unable to read state from fileno '$fileno': $!";
	}
	return $state;
}

__END__

