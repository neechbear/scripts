#!/usr/bin/perl -wT
############################################################
#
#   $Id: process_cpan_usage.pl 866 2006-12-24 17:02:07Z nicolaw $
#   process_cpan_usage.pl - Parse Weblogs for CPAN Module Install Submissions
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
use DBI qw();
use PerlIO::gzip qw();
use Regexp::Log::Common qw();
use Data::Dumper qw(Dumper);
use Date::Parse qw(str2time);
use Net::Whois::IP qw(whoisip_query);
use Memoize qw(memoize);
use POSIX qw(strftime);
use Storable qw(store);
use File::Basename qw(basename);
use Socket;

use vars qw($VERSION $DEBUG);
$VERSION = '0.01' || sprintf('%d', q$Revision: 956 $ =~ /(\d+)/g);
$DEBUG = $ENV{DEBUG} ? 1 : 0;

$| = 1;
memoize($_) for qw(whois ip2host host2ip);

my $dbh = DBI->connect('DBI:mysql:nicolaw:localhost','nicolaw','knickers',{RaiseError=>1});
recreate_tables($dbh);

my $xclf = new Regexp::Log::Common;
my @fields = $xclf->capture;
my $re = $xclf->regexp;

my @logs = grep(/\/access\.log(?:-\d{8}\.gz)?$/, sort
	glob("$ENV{HOME}/webroot/logs/perlgirl.org.uk/access.log*"));
push @logs, shift @logs;

my @submissions;
for my $log (@logs) {
	print 'Parsing '.basename($log).' ';
	my $mode = $log =~ /\.gz$/ ? '<:gzip' : '<';
	open(FH, $mode, $log) || die "Unable to close file '$log': $!";

	while (local $_ = <FH>) {
		next unless m,GET /lib/usage.cgi\?,;
		my $data = process_submission($_);
		$data->{mysql_insertid} = insert_row($dbh, $data);
		DUMP('%data', $data);
		push @submissions, $data;
		print '.';
	}

	close(FH) || die "Unable to close file '$log': $!";
	print "\n";
}

$dbh->disconnect;

store(\@submissions, 'usage_submissions.storable');
print Dumper(\@submissions);

exit;

sub insert_row {
	my ($dbh, $data) = @_;
	return unless defined $data->{param}->{name}
			&& defined $data->{param}->{version};

	my $sql = q{INSERT INTO submission
			(t,ip,host,module,version,os,arch,perl,agent,netas_id)
			VALUES (?,?,?,?,?,?,?,?,?,?)};
	my $sth = $dbh->prepare($sql);

	(my $module = $data->{param}->{name}) =~ s/-/::/g;
	my $netas_id = defined $data->{whois}->{origin}
				&& $data->{whois}->{origin} =~ /^AS\d+$/i
					? $data->{whois}->{origin}
					: undef;

	$sth->execute(
			strftime('%F %R', localtime($data->{unixtime})),
			$data->{ip},
			$data->{host},
			$module,
			$data->{param}->{version},
			$data->{param}->{osver},
			$data->{param}->{archname},
			$data->{param}->{perlver},
			$data->{ua},
			$netas_id,
		);
	my $mysql_insertid = $dbh->{mysql_insertid};
	$sth->finish;

	return $mysql_insertid;
}

sub process_submission {
	local $_ = shift;
	return unless m,GET /lib/usage.cgi\?(\S+),;

	my %data;
	my @pairs = split(/&/, $1);
	for my $pair (@pairs) {
		my ($k,$v) = split(/=/, $pair);
		$data{param}->{$k} = $v;
	}

	@data{@fields} = m/$re/;
	$data{unixtime} = str2time($data{ts});
	if (isIP($data{host})) {
		$data{ip} = $data{host};
		$data{host} = ip2host($data{ip});
	} else {
		$data{ip} = host2ip($data{host});
	}
	$data{whois} = whois($data{ip});

	return \%data;
}

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

sub recreate_tables {
	my $dbh = shift;
	for my $sql (@{get_sql_statements()}) {
		$dbh->do($sql);
	}
}

sub get_sql_statements {
	my @sql;
	my $sql;

	while (local $_ = <DATA>) {
		chomp;
		next if /^__END__/ || /^\s*$/ || /^\s*[;#]/;
		s/^\t+/ /g;
		$sql .= $_;
		if (/;\s*$/) {
			push @sql, $sql;
			$sql = '';
		}
	}

	DUMP('@sql',\@sql);
	return \@sql;
}

sub TRACE {
	return unless $DEBUG;
	warn(shift());
}

sub DUMP {
	return unless $DEBUG;
	eval {
		require Data::Dumper;
		$Data::Dumper::Indent = 2;
		$Data::Dumper::Terse = 1;
		warn(shift().': '.Data::Dumper::Dumper(shift()));
	}
}

__DATA__

DROP TABLE IF EXISTS `netas`;
CREATE TABLE netas (
	netas_id VARCHAR(8) NOT NULL PRIMARY KEY,
	descr VARCHAR(32)
);

DROP TABLE IF EXISTS `submission`;
CREATE TABLE submission (
	submission_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	t DATETIME NOT NULL,
	ip VARCHAR(15),
	host VARCHAR(255),
	module VARCHAR(48) NOT NULL,
	version DECIMAL(5,2) NOT NULL,
	os VARCHAR(8),
	arch VARCHAR(32),
	perl DECIMAL(8,6),
	agent VARCHAR(255),
	netas_id VARCHAR(8)
);

__END__

SELECT Module,Version, COUNT(*) AS Installs
	FROM submission
	WHERE
		(
			agent LIKE "lwp-trivial/%"
			OR agent LIKE "LWP::Simple/%"
			OR agent LIKE "Build.PL $Revision%"
		)
		AND ip NOT LIKE "132.185.144.%"
		AND ip NOT LIKE "85.158.42.2%"
		AND host NOT LIKE "%.tfb.net"
		AND module IN (
			"Parse::DMIDecode","WWW::WebStore::TinyURL","Colloquy::Data",
			"Colloquy::Bot::Simple","Apache2::AuthColloquy","WWW::VenusEnvy",
			"WWW::FleXtel","Sys::Filesystem","Proc::DaemonLite","WWW::Dilbert",
			"psmon","Tie::TinyURL","Util::SelfDestruct","RRD::Simple",
			"WWW::Comic","Parse::Colloquy::Bot","Bundle::Colloquy::BotBot2",
			"Apache2::AutoIndex::XSLT"
		)
	GROUP BY module,version;

wget -O - -q http://backpan.perl.org/authors/id/N/NI/NICOLAW/ | perl -ne 'if (($m) = /href="(\S+?)-\d+\.\d+.tar.gz"/) { $m =~ s/-/::/g; $m{$m}++; } END { print q{"}.join(qw{","},keys %m).qq{"\n}; }'

"Parse::DMIDecode","WWW::WebStore::TinyURL","Colloquy::Data","Colloquy::Bot::Simple","Apache2::AuthColloquy","WWW::VenusEnvy","WWW::FleXtel","Sys::Filesystem","Proc::DaemonLite","WWW::Dilbert","psmon","Tie::TinyURL","Util::SelfDestruct","RRD::Simple","WWW::Comic","Parse::Colloquy::Bot","Bundle::Colloquy::BotBot2","Apache2::AutoIndex::XSLT"

Apache2::AuthColloquy
Apache2::AutoIndex::XSLT
Bundle::Colloquy::BotBot2
Colloquy::Bot::Simple
Colloquy::Data
Parse::Colloquy::Bot
Parse::DMIDecode
Proc::DaemonLite
psmon
RRD::Simple
Sys::Filesystem
Tie::TinyURL
Util::SelfDestruct
WWW::Comic
WWW::Dilbert
WWW::FleXtel
WWW::VenusEnvy
WWW::WebStore::TinyURL

