#!/usr/bin/perl -w

use 5.6.1;
use strict;
use warnings;
use Socket;

my @data = <DATA>;
for (@data) {
	if (my ($chan,$nick,$irc,$host,$name) = $_ =~
			m/ -!- (#\S+) (\S+)\s+.+?(~\S+?\@(\S+)) \[(.+?)\]/) {
		my $ip = isIP($host) ? $host : host2ip($host);
		print "        # $chan $nick $irc [$name]\n";
		print "        Deny from $ip/32\n";
		print "\n";
	}
}

exit;

sub ip2host {
	my $ip = shift;
	my @numbers = split(/\./, $ip);
	my $ip_number = pack("C4", @numbers);
	my ($host) = (gethostbyaddr($ip_number, 2))[0];
	if (defined $host && $host) {
		return $host;
	} else {
		return $ip;
	}
}

sub isIP {
	return 0 unless defined $_[0];
	return 1 if $_[0] =~ /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.
						(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.
						(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.
						(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/x;
	return 0;
}

sub resolve {
	return ip2host(@_) if isIP($_[0]);
	return host2ip(@_);
}

sub host2ip {
	my $host = shift;
	my @addresses = gethostbyname($host);
	if (@addresses > 0) {
		@addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];
		return wantarray ? @addresses : $addresses[0];
	} else {
		return $host;
	}
}

__DATA__
