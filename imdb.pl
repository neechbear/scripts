#!/bin/env perl

# This is a crap script. It was thrown together in about 5 minutes.
# It's programming style is poor. Sorry. It is only a quick kludge
# I put together to fill up a personal DVD collection database for
# piping in to MySQL. I have made it publically available on the
# offchance that it might be useful for other people. Enjoy!
#	Nicola Worthington <nicolaw@cpan.org>

use strict;
use LWP::Simple;
use IMDB::Movie;
use Term::ReadLine;
use vars qw($VERSION);

$VERSION = sprintf('%d.%02d', q$Revision: 1.1 $ =~ /(\d+)/g);
(our $SELF = $0) =~ s|^.*/||;

our $term = new Term::ReadLine $SELF;

my $run = 1;
while ($run) {
	my $title = @ARGV ? join('%20',@ARGV) :
				$term->readline('Title?: ');
	if ($title =~ /^\s*(q|quit|exit)\s*$/i) {
		$run = 0;
		last;
	}
	$run = 0 if @ARGV;
	my @matches = do_search($title);
	my $result = select_result(@matches);
	if ($result) {
		print "Added IMDB record $result to database\n";
	}
}

print "Exiting\n\n";
exit;

sub do_search {
	my $title = shift;
	$title =~ s/ /%20/;
	my $html = get(sprintf('http://www.imdb.com/find?q=%s;s=tt',$title));
	my @matches;
	for (split(/\n+/,$html)) {
		if (m#href="/title/tt(\d+)/#) {
			push @matches, $1;
		}
	}
	return @matches;
}

sub select_result {
	my @matches = @_;
	for my $id (@matches) {
		my $movie = IMDB::Movie->new($id);
		my $movieid = $movie->id || $id;

		my $prompt = sprintf("[%d] %s (%s)? 'Y/n/q': ",$movieid,$movie->title,$movie->year);
		$_ = $term->readline($prompt);
		redo unless /^\s*(y|n|q(uit)?)?\s*$/i;
		return 0 if /q/i;

		if (/y/i) {
			open(DB,">>$ENV{HOME}/imdb.txt") || die "Unable to open imdb.txt: $!";
			# id,title,year,directors,writers,genres,user_rating,img
			print DB join("|", $movieid, $movie->title, $movie->year,
				join(';',@{$movie->director}), join(';',@{$movie->writer}),
				join(';',@{$movie->genres}), $movie->user_rating, $movie->img,
			), "\n";
			close(DB);
			return $movieid;
		}
	}
	return 0;
}




