#!/usr/bin/perl -wT

use 5.6.1;
use strict;
use warnings;
use POSIX qw();
use Getopt::Std qw();

use vars qw($VERSION);

$VERSION = '0.01' || sprintf('%d', q$Revision: 775 $ =~ /(\d+)/g);
$ENV{PATH} = '/bin:/usr/bin';
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Get command line options
my %opt = ();
$Getopt::Std::STANDARD_HELP_VERSION = 1;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
Getopt::Std::getopts('i:o:hvql?', \%opt) unless $@;
(VERSION_MESSAGE() && exit) if defined $opt{v};
(HELP_MESSAGE() && exit) if defined $opt{h} || defined $opt{'?'};
(HELP_MESSAGE() && exit) unless defined $opt{i} && defined $opt{o};

# Define all the record types and their constituent columns
my %event_columns = (
	'SERVICE ALERT'          => [qw(host service event_type state_type count info)],
	'SERVICE DOWNTIME ALERT' => [qw(host service event_type info)],
	'SERVICE FLAPPING ALERT' => [qw(host service event_type info)],
	'SERVICE NOTIFICATION'   => [qw(contact host service event_type command info)],
	'CURRENT SERVICE STATE'  => [qw(host service event_type state_type count info)],
	'INITIAL SERVICE STATE'  => [qw(host service event_type state_type count info)],

	'HOST ALERT'             => [qw(host event_type state_type count info)],
	'HOST DOWNTIME ALERT'    => [qw(host event_type info)],
	'HOST FLAPPING ALERT'    => [qw(host event_type info)],
	'HOST NOTIFICATION'      => [qw(contact host event_type command info)],
	'CURRENT HOST STATE'     => [qw(host event_type state_type count info)],
	'INITIAL HOST STATE'     => [qw(host event_type state_type count info)],

	'EXTERNAL COMMAND'       => undef,
	'PROGRAM_RESTART'        => undef,
	'LOG ROTATION'           => undef,
	'LOG VERSION'            => undef,

	'Caught SIGHUP'          => undef,
	'Caught SIGTERM'         => undef,
	'Finished daemonizing'   => undef,
	'Successfully shutdown'  => undef,
	'Bailing out due to'     => undef,
	'Nagios \d.\d starting'  => undef,
	'Error:'                 => undef,
	'Warning:'               => undef,
	);

my @sheet_cols = qw(time event contact host service event_type state_type count command info);
#my @sheet_cols = qw(time event);
#for my $cols (values %event_columns) {
#	next if !defined $cols || !@{$cols};
#	for my $col (@{$cols}) {
#		push @sheet_cols, $col unless grep($_ eq $col, @sheet_cols);
#	}
#}

my $match_re = '(?:'.join('|', keys %event_columns).')';
my %log_files = map { $_ => 0 } $opt{i} =~ /[\*\?]/
	? glob($opt{i})
	: split(/\s+/,$opt{i});

# Count the lines for a progress indicator bar
unless ($opt{q}) {
	require Term::ProgressBar;
	print "Calculating number of rows to process ...\n";
	for my $log_file (keys %log_files) {
		open(LOG,'<',$log_file) || die "Unable to open file handle LOG for file '$log_file': $!";
		$log_files{$log_file}++ while <LOG>;
		close(LOG) || warn "Unable to close file handle LOG for file '$log_file': $!";
	}
}

my $row_overall = 0;
my $row_curfile = 0;
my $total_rows = sum(values %log_files);
my $progress = Term::ProgressBar->new({
		count => $total_rows,
		ETA   => 'linear',
		name  => 'Progress',
		max_update_rate => 0.5,
	}) unless $opt{q};

# Open output
($opt{o}) = $opt{o} =~ /(.*)/;
open(OUT,'>',$opt{o}) || die "Unable to open file handle OUT for file '$opt{o}': $!";
print OUT join("\t",@sheet_cols)."\n";

# Process the lines 
for my $log_file (sort nagios_date keys %log_files) {
	open(LOG,'<',$log_file) || die "Unable to open file handle LOG for file '$log_file': $!";
	$row_curfile = 0;
	while (local $_ = <LOG>) {
		$row_overall++;
		$row_curfile++;

		# Extract time
		my ($time,$line) = $_ =~ /^\[([0-9]{1,13})\]\s+(.+)?\s*$/;
		next unless defined $time && defined $line;

		# Extract event
		$line =~ /^($match_re):?\s*(.*)?\s*$/;
		my $event = $1;
		$line = $2;

		# Only process events that we have columns defined for
		next if !defined $event_columns{$event} || !@{$event_columns{$event}};

		# Extract the data from the event to create an event record
		my $col = -1;
		my %rec = ( 'time' => POSIX::strftime('%F %T',localtime($time)), event => $event );
		for my $dat (split(/\s*;\s*/,$line,@{$event_columns{$event}})) { $col++;
			$dat = '' unless defined $dat;
			my $field = $event_columns{$event}->[$col];
			$rec{$field} = $dat;
		}

		# Generate output line from event record
		my @out;
		for my $col (@sheet_cols) {
			if (exists $rec{$col}) { push @out, $rec{$col}; }
			else { push @out, ''; }
		}
		print OUT join("\t",@out)."\n";

		$progress->update($row_overall) unless $opt{q};
	}
	close(LOG) || warn "Unable to close file handle LOG for file '$log_file': $!";
}

close(OUT) || warn "Unable to close file handle OUT for file '$opt{o}': $!";

exit;

sub sum {
	my $rtn = 0;
	for (@_) {
		$rtn += $_ if defined $_ && $_ =~ /^[\d\.]+$/;
	}
	return $rtn;
}

sub nagios_date {
	$a =~ /([0-2][0-9])-([0-3][0-9])-([1-2][0-9][0-9][0-9])-([0-9][0-9])/;
	my $A = sprintf('%04d%02d%02d%02d', $3, $1, $2, $4);

	$b =~ /([0-2][0-9])-([0-3][0-9])-([1-2][0-9][0-9][0-9])-([0-9][0-9])/;
	my $B = sprintf('%04d%02d%02d%02d', $3, $1, $2, $4);

	return $A <=> $B;
}

sub HELP_MESSAGE {
	print qq{Syntax: nagioslog2tab.pl [-i input files] [-o output file] [-h|-v]
   -i <file(s)>    List of input Nagios log files to process
   -o <file>       Output CVS file name
   -q              Run in quiet mode
   -v              Display version information
   -h              Display this help
\n};
}

sub VERSION { &VERSION_MESSAGE; }
sub VERSION_MESSAGE {
	print "$0 version $VERSION ".'($Id: nagioslog2tab.pl 775 2006-10-08 18:47:33Z nicolaw $)'."\n";
}

__END__

