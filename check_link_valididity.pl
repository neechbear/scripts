#!/usr/bin/perl -w

use strict;
use DBI;
use LWP::UserAgent;
use Getopt::Std qw();

use vars qw($VERSION);
($VERSION) = ('$Revision: 1.2 $' =~ /([\d\.]+)/);

my $opts = {};
Getopt::Std::getopt('shv', $opts);

if (exists $opts->{h}) {
	require Pod::Usage;
	Pod::Usage::pod2usage(-verbose => 2);
	exit;
} elsif (exists $opts->{v}) {
	print '$Id: check_link_valididity.pl,v 1.2 2004/11/24 18:00:48 nicolaw Exp $'."\n";
	exit;
}

my $ua = LWP::UserAgent->new;
$ua->timeout(20);
$ua->env_proxy;

my $dbh = DBI->connect('dbi:mysql:shesnotthere:localhost','shesnotthere','knickers');
my $sql = 'SELECT * FROM links WHERE broken IS NULL OR UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(broken) < 604800';
$sql = 'SELECT * FROM links WHERE broken IS NOT NULL' if exists $opts->{s};
my $sth = $dbh->prepare($sql);
$sth->execute();

while (my $link = $sth->fetchrow_hashref()) {
	my $response = $ua->get($link->{url});
	if ($response->is_success) {
		printf STDOUT ("%s => %s\n", $link->{url}, $response->status_line);
		my $sth = $dbh->prepare(sprintf('UPDATE links SET last_tested_good = NOW(), broken = NULL WHERE id = ?'));
		$sth->execute($link->{id});
	
	} else {
		printf STDERR ("%s => %s\n", $link->{url}, $response->status_line);
		unless ($link->{broken}) {
			my $sth = $dbh->prepare(sprintf('UPDATE links SET broken = NOW() WHERE id = ?'));
			$sth->execute($link->{id});
		}
	}
}

$sth->finish();
$dbh->disconnect();

exit;

=pod

=head1 NAME

check_link_valididity.pl - Check that links in the database are reachable

=head1 SYNOPSYS

    ./check_link_valididity.pl         Default operation
    ./check_link_valididity.pl -v      Show version information
    ./check_link_valididity.pl -h      Show this help information
    ./check_link_valididity.pl -s      Run in stale mode (check broken links only)

=head1 DESCRIPTION

Does what it says on the tin.

=head1 VERSION

$Revision: 1.2 $

=head1 AUTHOR

Nicola Elizabeth Worthington <nicolaworthington@msn.com>

http://www.nicolaworthington.com

$Author: nicolaw $

=head1 CHANGES

$Log: check_link_valididity.pl,v $
Revision 1.2  2004/11/24 18:00:48  nicolaw
Couple of typos

Revision 1.1  2004/11/24 17:58:13  nicolaw
Adding


=cut

