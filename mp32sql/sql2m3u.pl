#!/usr/bin/perl -wT

use strict;
use warnings;
use English;
use Getopt::Std;
use DBI;
use Term::ProgressBar;
use URI::Escape;

use vars qw($VERSION);

map {$ENV{$_} ||= ''} qw(LANG PATH LOGNAME HOME USER TERM HOSTNAME);
%ENV = map {$_ => $ENV{$_}} qw(LANG PATH LOGNAME HOME USER TERM HOSTNAME);
$ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
$OUTPUT_AUTOFLUSH++;

my %opts;
getopts('qvhVD:u:p:t:H:d:r:', \%opts);
help() if exists $opts{h};
version() if exists $opts{v};

my $dbi_hostname = $opts{H} || 'localhost';
my $dbi_database = $opts{D} || 'mp3';
my $dbi_table = $opts{t} || 'mp3';
my $dbi_username = $opts{u} || 'mp3';
my $dbi_password = $opts{p} || 'mp3';

my $root_prefix = $opts{r} || 'http://www.nicolaworthington.com/mp3/';

my $output_directory = $opts{d} || '/home/nicolaw/webroot/www/playlists';
if ($output_directory =~ /^(.+)$/) { $output_directory = $1; }
chdir $output_directory || die "Failed to change working directory to $output_directory\n";

my $dbh = DBI->connect(sprintf('DBI:mysql:%s:%s',$dbi_database,$dbi_hostname),$dbi_username,$dbi_password);
my $sql = 'SELECT * FROM mp3 ORDER BY path,artist,album,tracknum,file';
my $sth = $dbh->prepare($sql);
my $total_files = $sth->execute();

my $progress = Term::ProgressBar->new({	name  => 'Export progress',
					count => $total_files,
					ETA   => 'linear', });
$progress->max_update_rate(1);

my $next_update = 0;
my $imported_files = write_playlist($output_directory,1);
$progress->update($total_files) if $total_files >= $next_update;

$sth->finish();
$dbh->disconnect();

sub write_playlist {
	my $output_directory = shift;

	my $last_playlist_filename = '';
	my $playlist_filename = '';
	my $exported = 0;

	while (my $href = $sth->fetchrow_hashref()) {
		my $path;
		for (split(/\//,$href->{path})) {
			$path .= uri_escape($_).'/';
		}
		chop $path;
	
		my $title = $href->{title} || $href->{file};
		$title =~ s/[_]+/ /; $title =~ s/\.mp3$//i;
		$title =~ s/´/'/g; $title =~ s/[^a-zA-Z0-9 \-,\.\'\"\?\!\[\]\{\}\(\)]//g;

		$playlist_filename = munge_playlist_filename($href);
		next unless $playlist_filename;
		$playlist_filename = sprintf('%s/%s', $output_directory, $playlist_filename);

		if ($playlist_filename ne $last_playlist_filename) {
			close(PLAYLIST) if $last_playlist_filename;
			open(PLAYLIST,">$playlist_filename");
			print PLAYLIST "#EXTM3U\n";
		}

		printf PLAYLIST "#EXTINF:%d,%s\n",int $href->{secs},$title;
		printf PLAYLIST "%s%s/%s\n",$root_prefix,$path,uri_escape($href->{file});

		$exported++;
		$next_update = $progress->update($exported) if $exported > $next_update;
		$last_playlist_filename = $playlist_filename;
	}

	close(PLAYLIST);
}

sub munge_playlist_filename {
	my $href = shift;

	my $playlist_filename = (split('/',$href->{path}))[1];
	return undef unless $playlist_filename;

	$playlist_filename =~ s/\s+/_/g;
	$playlist_filename =~ s/[^a-z0-9\_\-]//gi;
	$playlist_filename .= '.m3u';

	return $playlist_filename;
}

sub help {
	print <<FOO;
Syntax: $PROGRAM_NAME [-v] [-h] [-q|-V] [-D database] [-t table] [-u username] [-p password] [-H hostname] [-d directory] [-r path]
	-v        Display version information
	-h        Display this help information
	-q        Quiet output
	-V        Verbose output
	-D        Specify DBI database to use
	-t        Specify DBI table to use
	-u        Specify DBI username to use
	-p        Specify DBI password to use
	-H        Specify DBI hostname to use
	-d dir    Directory to output .m3u files to
	-r str    Full path or URL to prefix MP3 paths with
FOO
	exit 0;
}

sub version {
	printf "%s\n",'$Id$';
	exit 0;
}

__END__


drop table mp3;
create table mp3 (
	id int unsigned not null primary key auto_increment,
	path varchar(255),
	file varchar(255),
	year year,
	artist varchar(255),
	comment varchar(255),
	album varchar(255),
	title varchar(255),
	genre varchar(255),
	tracknum int(2) unsigned,
	tagversion varchar(255),
	frequency varchar(255),
	size varchar(255),
	vbr varchar(255),
	time varchar(255),
	ms varchar(255),
	stereo varchar(255),
	secs varchar(255),
	frames varchar(255),
	padding varchar(255),
	mm varchar(255),
	copyright varchar(255),
	bitrate varchar(255),
	version varchar(255),
	frame_length varchar(255),
	ss varchar(255),
	layer varchar(255),
	mode varchar(255)
);


