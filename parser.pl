#!/home/nicolaw/webroot/perl/bin/perl -w

use strict;
use Data::Dumper;
use LWP::UserAgent;
use HTML::Entities;

$|++;

my $ua = LWP::UserAgent->new(agent => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0)');

my @films = ();

while (local $_ = <>) {
	chomp;
	my ($imdbid,@data) = split(/\|/,$_);

	$imdbid =~ s/^tt//;
	my %record;
	print "[$imdbid] ";

	#	http://www.imdb.com/title/tt0120623/combined
	my $resp = $ua->get("http://www.imdb.com/title/tt$imdbid/combined");
	unless ($resp->is_success) {
		warn $resp->status_line;
	} else {
		my $html = $resp->content;
		my ($title,$year,@flags) = $html =~
			m,<title>\s*(.+?)\s+\(((?:19|20)\d\d(?:/I)?)\)\s*(?:\(([A-Z]+)\)?\s*)*\s*</title>,gsmi;
		my @genres = $html =~ m,<a href="/Sections/Genres/[A-Z]+/?">\s*(.+?)\s*</a>,gsmi;
		my ($tagline) = $html =~ m,<[^>]+>\s*Tagline:\s*</[^>]+>\s*(.+?)\s*<[^>]+>,smi;
		my ($image) = $html =~ m,<a name="poster"[^>]*><img .+? src="(http://ia.imdb.com/media/imdb/.+?)".+?></a>,smi;
		my ($rating) = $html =~ m,<a href="/List\?certificates=UK:.+">UK:(.+?)</a>,smi;

		%record = (
				imdbid => "tt$imdbid",
				title => decode_entities($title),
				year => $year,
				tagline => decode_entities($tagline||''),
				image => $image,
				certification => $rating,
				genres => \@genres,
				flags => \@flags,
			);
	}

	#	http://www.imdb.com/title/tt0120623/keywords
	$resp = $ua->get("http://www.imdb.com/title/tt$imdbid/keywords");
	unless ($resp->is_success) {
		warn $resp->status_line;
	} else {
		my $html = $resp->content;
		my %keywords = $html =~ m,<a href="/keyword/(.+?)/">(.+?)</a>,gsmi;
		$keywords{$_} = decode_entities($keywords{$_}) for keys %keywords;
		$record{keywords} = \%keywords;
	}

	#	http://www.imdb.com/title/tt0120623/fullcredits
	$resp = $ua->get("http://www.imdb.com/title/tt$imdbid/fullcredits");
	unless ($resp->is_success) {
		warn $resp->status_line;
	} else {
		my $html = $resp->content;
		if (my ($html) = $html =~ m,(<table [^>]+><tr><td [^>]+><a name="directors" .+?</table>),smi) {
			my %directors = $html =~ m,<a href="/name/([a-z0-9]+)/">(.+?)</a>,gsmi;
			$directors{$_} = decode_entities($directors{$_}) for keys %directors;
			$record{directors} = \%directors;
		}
		if (my ($html) = $html =~ m,(<table [^>]+><tr><td [^>]+><a name="producers" .+?</table>),smi) {
			my %producers = $html =~ m,<a href="/name/([a-z0-9]+)/">(.+?)</a>,gsmi;
			$producers{$_} = decode_entities($producers{$_}) for keys %producers;
			$record{producers} = \%producers;
		}
		if (my ($html) = $html =~ m,(<table [^>]+><tr><td [^>]+><a name="writers" .+?</table>),smi) {
			my %writers = $html =~ m,<a href="/name/([a-z0-9]+)/">(.+?)</a>,gsmi;
			$writers{$_} = decode_entities($writers{$_}) for keys %writers;
			$record{writers} = \%writers;
		}

		if (my ($html) = $html =~ m,(<table [^>]+><tr><td [^>]+><a .+?href="/Glossary/C#cast">.+?</table>),smi) {
			my %cast = $html =~ m,<a href="/name/([a-z0-9]+)/">(.+?)</a>,gsmi;
			$cast{$_} = decode_entities($cast{$_}) for keys %cast;
			$record{cast} = \%cast;
		}
	}

	push @films, \%record;

	print "Writing $record{imdbid} ... ";
	if (open(FH,'>',$record{imdbid})) {
		print "done\n";
		print FH Dumper(\%record);
		close(FH);
	} else {
		print "$!\n";
	}
}

