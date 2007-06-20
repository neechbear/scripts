#!/usr/bin/perl -w

use 5.6.1;
use strict;
use warnings;
use LWP::Simple qw(get);
use Storable qw(store retrieve);
use File::Basename qw(fileparse);

my $cache = 'bbcram.dat';
my $urls = -f $cache ? retrieve($cache) : get_programmes();
store($urls,$cache) if !-f $cache;

my $filter = $ARGV[0] || '';
my @results = grep(/$filter.*\.ra$/i,sort keys %{$urls});
if (@results == 1) {
	my ($file,$dir,$ext) = fileparse($results[0], qr/\.[^.]*/);
	print "mplayer -ao pcm:file=$file.wav $results[0] && lame $file.wav $file.mp3 && rm -fv $file.wav\n";
} else {
	print "$_\n" for @results;
}

exit;

sub get_programmes {
	my $url = shift;
	$url ||= 'http://www.bbc.co.uk/radio/aod/index_noframes.shtml';
	(my $parent_path = (split(/\//, $url, 4))[3]) =~ s/\/[^\/]*$//;

	my $urls = shift;
	$urls = { $url => 1 } unless defined $urls && ref($urls) eq 'HASH';

	warn "Getting $url ...\n";
	my $html = get($url);

	my $regex =
		$url =~ /index_noframes/ ? qr!(["'])(/radio/aod/[^'"]+?/audiolist\.shtml)\1! :#"
		$url =~ /audiolist/      ? qr!(["'])(aod\.shtml\?.+?)\1! :		#"
		$url =~ /aod\.shtml/     ? qr!(["'])(/radio/aod/.+?\.ram)\1! :		#"
		$url =~ /\.ram/          ? qr!()(rtsp://.+?\.ra)! :			#"
			   qr!NO MATCH!;						#"

	while ($html =~ m!$regex!gi) {
		my $path = $2;
		if ($path =~ /\.ra$/) {
			$urls->{$path} = 1;
		} else {
			my $url = "http://www.bbc.co.uk";
			$url .= "/$parent_path/" unless $path =~ m,^/,;
			$url .= $path;

			if (!exists($urls->{$url})) {
				$urls->{$url} = 1;
				get_programmes($url,$urls);
			}
		}
	}

	return $urls;
}

__END__

