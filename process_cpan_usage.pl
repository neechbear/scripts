#!/usr/bin/perl -w

use 5.6.1;
use strict;
use warnings;
use DBI qw();
use PerlIO::gzip qw();
use Regexp::Log::Common qw();
use Data::Dumper qw(Dumper);
use Date::Parse qw(str2time);
use Net::Whois::IP qw(whoisip_query);
use Memoize qw(memoize);
use Storable qw(store);
use Socket;

$| = 1;
memoize('whois');
memoize('ip2host');
memoize('host2ip');

my @submissions;
my $dbh = DBI->connect('DBI:mysql:nicolaw:localhost','nicolaw','knickers',{RaiseError=>1});

my $foo = new Regexp::Log::Common;
my @fields = $foo->capture;
my $re = $foo->regexp;

my @logs = grep(/\/access\.log(?:-\d{8}\.gz)?$/,
			sort glob("$ENV{HOME}/webroot/logs/perlgirl.org.uk/access.log*")
		);
push @logs, shift @logs;

for my $log (@logs) {
	print "Parsing $log ";
	my $fh;
	if ($log =~ /\.gz$/) {
		open($fh, '<:gzip', $log) || die "Unable to close file '$log': $!";
	} else {
		open($fh, '<', $log) || die "Unable to close file '$log': $!";
	}

	while (local $_ = <$fh>) {
		next unless m,GET /lib/usage.cgi\?(\S+),;
		my @pairs = split(/&/, $1);
		my %data;
		@data{@fields} = m/$re/;
		$data{unixtime} = str2time($data{ts});
		for my $pair (@pairs) {
			my ($k,$v) = split(/=/, $pair);
			$data{param}->{$k} = $v;
		}
		$data{whois} = whois($data{host});
		print '.';
		push @submissions, \%data;
	}

	close($fh) || die "Unable to close file '$log': $!";
	print "\n";
}

$dbh->disconnect;

store(\@submissions, 'usage_submissions.storable');
print Dumper(\@submissions);

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

sub whois {
	return whoisip_query(shift);
}

__DATA__
create table cpan (
	t datetime not null,
	ip varchar(15) not null,
	module varchar(48) not null,
	os varchar(8) not null,
	arch varchar(16) not null,
	perl decimal(8,6) not null,
	agent varchar(32) not null
);

__END__


