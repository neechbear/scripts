#!/usr/bin/perl -wT

use strict;
use warnings;
use English;
use MP3::Info;
use Getopt::Std;
use DBI;
use Term::ProgressBar;
use Cwd;

use vars qw($VERSION);

map {$ENV{$_} ||= ''} qw(LANG PATH LOGNAME HOME USER TERM HOSTNAME);
%ENV = map {$_ => $ENV{$_}} qw(LANG PATH LOGNAME HOME USER TERM HOSTNAME);
$ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
$OUTPUT_AUTOFLUSH++;

my %opts;
getopts('qvhVD:u:p:t:H:d:', \%opts);
help() if exists $opts{h};
version() if exists $opts{v};

my $dbi_hostname = $opts{H} || 'localhost';
my $dbi_database = $opts{D} || 'mp3';
my $dbi_table = $opts{t} || 'mp3';
my $dbi_username = $opts{u} || 'mp3';
my $dbi_password = $opts{p} || 'mp3';

my $root_directory = $opts{d} || '/u1/mp3';
if ($root_directory =~ /^(.+)$/) { $root_directory = $1; }
chdir $root_directory || die "Failed to change working directory to $root_directory\n";

my $total_files = scan_directory($root_directory,0);
my $progress = Term::ProgressBar->new({	name  => 'Import progress',
					count => $total_files,
					ETA   => 'linear', });
$progress->max_update_rate(1);

my $dbh = DBI->connect(sprintf('DBI:mysql:%s:%s',$dbi_database,$dbi_hostname),$dbi_username,$dbi_password);
my @fields = qw(path file year artist comment album title genre tracknum tagversion frequency size vbr time ms stereo secs frames padding mm copyright bitrate version frame_length ss layer mode);
my $placeholders = '?,'x@fields; chop $placeholders;
my $sth = $dbh->prepare(sprintf('INSERT INTO %s (%s) VALUES (%s)',$dbi_table,join(',',@fields),$placeholders));

my $next_update = 0;
my $imported_files = scan_directory($root_directory,1);
$progress->update($total_files) if $total_files >= $next_update;
print "$imported_files of $total_files were imported.\n";

$sth->finish();
$dbh->disconnect();

sub scan_directory {
	my $scan_directory = shift;
	my $import_files = shift || 0;
	if ($scan_directory =~ /^(.+)$/i) { $scan_directory = $1; }
	chdir $scan_directory || die "Unable to change directory to '$scan_directory'";

	my $total_files = 0;
	if (opendir(DH,$scan_directory)) {
		my @files = grep(!/^\./,readdir(DH));
		closedir(DH);

		for my $file (@files) {
			if (-f $file) {
				if ($import_files) {
					# $total_files += import_file($file) || 1;
					$total_files += import_file($file);
					$next_update = $progress->update($total_files) if $total_files > $next_update;
				} else {
					$total_files++;
				}

			} elsif (-d $file) {
				my $more_files = scan_directory("$scan_directory/$file",$import_files);
				$total_files += $more_files;
			}
		}
	}

	chdir '..' || die "Unable to change directory to '..'";
	return $total_files;
}

sub import_file {
	my $file = shift;
	my $imported_okay = 0;

	my $fh;
	if (open($fh,$file)) {
		my $info = get_mp3info($fh) || {}; my %info = %{$info};
		if ($info->{SECS}) {
			my $tag = get_mp3tag($fh) || {}; my %tag = %{$tag};
			(my $path = cwd) =~ s/^$root_directory\///;
			if ($sth->execute($path,$file,@tag{qw(YEAR ARTIST COMMENT ALBUM TITLE GENRE TRACKNUM TAGVERSION)},@info{qw(FREQUENCY SIZE VBR TIME MS STEREO SECS FRAMES PADDING MM COPYRIGHT BITRATE VERSION FRAME_LENGTH SS LAYER MODE)})) {
				$imported_okay++;
			}
		}
		close($fh);
	}

	return $imported_okay;
}

sub help {
	print <<FOO;
Syntax: $PROGRAM_NAME [-v] [-h] [-q|-V] [-D database] [-t table] [-u username] [-p password] [-H hostname] [-d directory]
	-v        Display version information
	-h        Display this help information
	-q        Quiet output
	-V        Verbose output
	-D        Specify DBI database to use
	-t        Specify DBI table to use
	-u        Specify DBI username to use
	-p        Specify DBI password to use
	-H        Specify DBI hostname to use
	-d dir    Scan a specific directory tree
FOO
	exit 0;
}

sub version {
	printf "%s\n",'$Id: mp32sql.pl,v 1.3 2004/10/19 20:02:19 nicolaw Exp $';
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


