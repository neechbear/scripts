#!/usr/bin/perl -w

use 5.004;
use strict;
use warnings;
use Getopt::Std qw(getopts);
use LWP::Simple qw(get);
use File::Glob qw(:glob);
use vars qw($VERSION);

$VERSION = '0.01' || sprintf('%d', q$Revision$ =~ /(\d+)/g);
$ENV{PATH} = '/bin:/usr/bin';
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
$Getopt::Std::STANDARD_HELP_VERSION = 1;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

my $opt = { d => './'};
Getopt::Std::getopts('S:s:d:hv?', $opt) unless $@;
(HELP_MESSAGE() && exit) if defined $opt->{h} || defined $opt->{'?'} || !defined $opt->{s};
(VERSION_MESSAGE() && exit) if defined $opt->{v};

if (defined $opt->{d}) {
	chdir $opt->{d} || die "Failed to chdir to '$opt->{d}'; $!\n";
}

my $url = "http://epguides.com/$opt->{s}/";
print "Retrieving $url ...";
my $data = get($url) || '';
print $data ? " done\n" : " error\n";

for (split(/[\r\n]/,$data)) {
	next unless /\s+([0-9]+)-\s*([0-9]+)\s+/;
	my ($s,$e) = ($1,sprintf('%02d',$2));
	next if defined $opt->{S} && $opt->{S} =~ /^[0-9]+$/ && $s != $opt->{S};

	if (/">(.*?)<\/a>/) {
		(my $episode = $1) =~ s/\//-/g;
		my $base = sprintf("%s - %d%s%02d - %s", $opt->{s}, $s, 'x', $e, $episode);

		for my $glob ((
						"*.${s}X${e}.*",	"*.${s}x${e}.*",
						"* ${s}X${e}.*",	"* ${s}x${e}.*",
						"* ${s}X${e} - *",	"* ${s}x${e} - *",
						"*_${s}X${e}_*",	"*_${s}x${e}_*",
						"*S0${s}E${e}*",	"*s0${s}e${e}*",
						"*S${s}E${e}*",		"*s${s}e${e}*",
						"* - ${s}x${e} - *","* - ${s}X${e} - *",
						"*.${s}${e}.*",		"* - ${s}${e} - *",
						"$opt->{s} ${s}${e} *",
						"${s}${e} - *",		"* - ${s}${e} - *",
					)) {

			my @files = glob($glob);
			if (@files == 1) {
				my $old = $files[0];
				(my $ext = $old) =~ s/.*\.//;
				my $new = $base.'.'.lc($ext);
				next if $old eq $new;
				print "Renaming \"$old\" to \"$new\" ...";
				if (rename($old, $new)) {
					print " okay\n";
				} else {
					print " $!\n";
				}
			}

		}
	}
}

exit;


sub HELP_MESSAGE {
        print qq{Syntax: epguideRename.pl <-s series> [-S season] [-d directory] [-h|-v]
   -s     Television series
   -S     Season number
   -d     Video directory
   -v     Display version information
   -h     Display this help
\n};
}

sub VERSION { &VERSION_MESSAGE; }
sub VERSION_MESSAGE {
        print "$0 version $VERSION ".'($Id$)'."\n";
}

__END__


