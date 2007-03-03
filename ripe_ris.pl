#!/usr/bin/perl -w
############################################################
#
#   $Id: ripe_ris.pl 968 2007-03-03 22:04:15Z nicolaw $
#   ripe_ris.pl - Query Routes from RIPE RIS WHOIS Server
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
use IO::Socket;
use Data::Dumper qw(Dumper);

my $qry = shift || die "Syntax: $0 <ip>\n";
print Dumper(routes($qry));

exit;


sub best_route {

}


sub routes {
	my $qry = shift;

	my @data;
	my %block;
	for (split(/[\r\n]/,whois($qry))) {
		next if /^\s*[;#%]/;
		if (/^\s*(\S+?):\s+(.+?)\s*$/) {
			$block{$1} = $2;
		} elsif (keys %block && /^\s*$/) {
			push @data, {%block};
			%block = ();
		}
	}
	push @data, {%block} if keys %block;

	return \@data;
}


sub whois {
	my $qry = shift;

	my $host = 'riswhois.ripe.net';
	my $data;

	eval {
		local $SIG{ALRM} = sub { die 'Timed Out'; };
		alarm 3;
		my $sock = IO::Socket::INET->new(
				PeerAddr => inet_ntoa( inet_aton($host) ),
				PeerPort => 'whois',
				Proto => 'tcp',
				## Timeout => ,
			);
		$sock->autoflush;
		print $sock "$qry\015\012";
		local $/ = undef;
		$data = <$sock>;
		alarm 0;
	};

	alarm 0;
	return "Error: Timeout" if $@ && $@ =~ /Timed Out/;
	return "Error: $@" if $@;

	return $data;
}


__END__

