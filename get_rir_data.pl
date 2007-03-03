#!/usr/bin/perl -w
############################################################
#
#   $Id: get_rir_data.pl 866 2006-12-24 17:02:07Z nicolaw $
#   get_rir_data.pl - Get RIR Data
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

use 5.8.0;
use strict;
use warnings;
use POSIX qw(strftime);
use WWW::Curl::Easy;
use Data::Dumper;
use Storable qw(store retrieve);

my $dumpfile = 'foo.storable';
my $records = {};

if (-f $dumpfile) {
	$records = retrieve($dumpfile);
} else {
	$records = get_live_data();
	store($records, $dumpfile);
}

print Dumper($records);

exit;


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
		undef $/; $data = <$sock>; $/ = "\n";
		alarm 0;
	};

	alarm 0; # race condition protection
	return "Error: Timeout." if ( $@ && $@ =~ /Timed Out/ );
	return "Error: Eval corrupted: $@" if $@;

	return $data;
}


sub get_live_data {
	my %records = (
			version => [],
			summary => [],
			record  => [],
		);

	my %format = (
			version => [qw(version registry serial records startdate enddate UTCoffset)],
			summary => [qw(registry unused1 type unused2 count summary)],
			record  => [qw(registry cc type start value date status)],
		);

	my @urls = (
			'ftp://ftp.arin.net/pub/stats/afrinic/delegated-afrinic-latest',
			'ftp://ftp.arin.net/pub/stats/apnic/delegated-apnic-latest',
			'ftp://ftp.arin.net/pub/stats/arin/delegated-arin-latest',
			'ftp://ftp.arin.net/pub/stats/lacnic/delegated-lacnic-latest',
			'ftp://ftp.arin.net/pub/stats/ripencc/delegated-ripencc-latest',
		);

	foreach my $url (@urls) {
		open(my $fh, '>', \my $dat) || die "Failed to open file handle: $!";
		my $curl = new WWW::Curl::Easy;
		$curl->setopt(CURLOPT_URL, $url);
		$curl->setopt(CURLOPT_FTP_USE_EPSV, '0');
		$curl->setopt(CURLOPT_FILE, $fh);
		if ($curl->perform != 0) {
			print "Failed: ".$curl->errbuf."\n";
		}

		my $line = 0;
		for (split(/[\n\r]+/,$dat)) {
			$line++;
			next if /^\s*#/ || /^\s*$/;

			my @cols = split(/\|/,$_);
			my $type = 'record';

			if ($line == 1) {
				$type = 'version';
			} elsif ($cols[5] eq 'summary' && $#cols == 5) {
				$type = 'summary';
			} elsif ($#cols >= 6) {
				$type = 'record';
			}

			my %data;
			@data{@{$format{$type}}} = @cols;

			if ($type eq 'record' && $data{type} eq 'ipv4') {
				my @octets_start = split(/\./, $data{start});
				$data{long_start} = 0;
				foreach my $octet_start (@octets_start) {
					$data{long_start} <<= 8;
					$data{long_start} |= $octet_start;
				}
				$data{long_end} = $data{long_start} + ($data{value} - 1);

				get_end: {
					my $x = $data{long_end};
					my @end_octets;
					for (0 .. $#octets_start) {
						push @end_octets, $x & 0xff;
						$x >>= 8;
					}
					$data{end} = join('.',reverse(@end_octets));
				}
			}

			push @{$records{$type}}, \%data;
		}

		close($fh) || die "Unable to close file handle: $!";
	}

	return \%records;
}


__END__

http://www.cidr-report.org/cgi-bin/as-report?as=AS10962
http://www.ripe.net/ris/tools/index.html
http://www.ripe.net/projects/ris/tools/riswhois.html

http://resources.potaroo.net/iso3166/iso3166tablecc.html
http://resources.potaroo.net/iso3166/regiontablecc.html

CREATE TABLE ip_map (
    country_id char(2) DEFAULT NULL,
    registry enum('afrinic','apnic','arin','lacnic','ripencc') DEFAULT NULL,
    ip_from double default NULL,
    ip_to double default NULL,
    UNIQUE KEY registry (registry,ip_from,ip_to)
);

http://www.iana.org/ipaddress/ip-addresses.htm
http://www.apnic.net/services/asn_guide.html

ftp://ftp.afrinic.net/pub/stats/
ftp://ftp.apnic.net/pub/stats/
ftp://ftp.arin.net/pub/stats/
ftp://ftp.lacnic.net/pub/stats/
ftp://ftp.ripe.net/pub/stats/


