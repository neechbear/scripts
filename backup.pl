#!/usr/bin/perl -w

###############################################################################
# Load modules

use strict;
use warnings;
use English;
package Sys::Script::Backup;

use Getopt::Mixed ();
use FileHandle ();
use Sys::Filesystem ();
use Config::General ();
use File::Spec ();
use POSIX ();
use File::Temp ();










###############################################################################
# Define globals, constants and overloaded subs

use constant DEBUG => $ENV{DEBUG} ? 1 : 0;
use vars qw($VERSION);
use subs qw(die);
($VERSION) = ('$Revision$' =~ /([\d\.]+)/ );










###############################################################################
# Init

# Get command line options
my $self = __PACKAGE__->init;
DUMP('$self',$self);
$self->process_command_line_options($self);
if ($self->{version}) {
	print '$Id$'."\n";
	exit 1;
}

# Close stderr and stdoutif we have very-quiet set
if ($self->{'very-quiet'}) {
	$self->{quiet}++;
	$self->close_stderr();
	$self->close_stdout();
}

# Enable optional tracing
eval {
	require Tracing;
	import Tracing qw(print) if $self->{trace};
	deep_import Tracing qw(print) if $self->{'deep-trace'};
};

# Display help
if ($self->{help}) {
	require Pod::Usage;
	Pod::Usage::pod2usage(-verbose => 2);
}

# Read configuration file
$self->read_config_file($self->{config});

# Get source and destination
die(2,"You must specify a target destination.\n") unless @ARGV;
$self->{destination} = pop @ARGV;
if (@ARGV) {
	$self->{sources} = [ (@ARGV) ];
} else {
	$self->{sources} = [ ($self->gather_filesystem_sources) ];
}

# No source
die(3,"Could not locate any valid sources.\n") unless @{$self->{sources}} > 0;

# Find system commands
$self->{system_commands} = $self->find_system_commands(qw(ufsdump ufsrestore mt
										tar bzip2 bunzip2 gzip gunzip compress
										uncompressfind cpio));

# Debug
DUMP('$self',$self);

## Close stdout unless we have verbose set
#$self->close_stdout unless $self->{verbose};

## Close stderr if we have very-quier set
#$self->close_stderr if $self->{'very-quiet'};

# Backup
$self->{archivehandler} = 'tar' if $self->{tar};
$self->{archivehandler} = 'ufsdump' if $self->{ufsdump};
$self->{quiet} || $self->log('Calling archive handler to start backup');
if (lc($self->{archivehandler}) eq 'ufsdump') {
	$self->ufsdump_archive_handler;
} elsif (lc($self->{archivehandler}) eq 'tar') {
	$self->tar_archive_handler;
}
$self->{quiet} || $self->log('Returned from archive handler');

# Open stdout if we closed it
$self->open_stdout if $self->{close_stdout};

# Open stderr if we closed it
$self->open_stderr if $self->{close_stderr};










###############################################################################
# Built-in archive handlers

sub ufsdump_archive_handler {
	my $self = shift;

	# Check we have the right commands before we do anything
	$self->must_have_commands(qw(ufsdump mt ufsrestore));

	# Ignore compression options
	if ($self->{bzip2} || $self->{gzip} || $self->{compress}) {
		die(4,"ufsdump archive handler does not support compression.");
	}

	# Backup each source
	for my $source (@{$self->{sources}}) {
		# Ensure destination is a file
		my $destination = $self->{destination};
		if (-d $destination) {
			$destination = File::Spec->catfile($destination,
								join('_',sprintf('%s%s',(File::Spec->splitpath($source)||'root'),'.ufsdump'))
							);
		}

		# /usr/sbin/ufsdump 0bdsfnu 64 80000 150000 /dump/backup/dylan/hostdumps/dylan_u03.ufsdump.level.0 /u03
		# /usr/sbin/ufsdump [options] [arguments] files_to_dump
		my $command_to_execute = sprintf('%s %s %s %s',
									$self->{system_commands}->{ufsdump},
									'0bdsfnu 64 80000 150000',
									$destination,
									$source
								);
		my ($exit_status, $signal_num, $dumped_core, $stdout, $stderr)
				= $self->execute_system_command($command_to_execute);
	}

	if (-f $self->{destination}) {
		# Rewind the tape
		my $command_to_execute = sprintf('%s -f %s %s',
								$self->{system_commands}->{mt},
								$self->{destination},
								'rewind'
							);
	}

	# Skip verification stage
	return if $self->{'no-verify'};

	# Verify each source
	for (my $count = 1; $count <= @{$self->{sources}}; $count++) {
		# Ensure destination is a file
		my $destination = $self->{destination};
		if (-d $destination) {
			$destination = File::Spec->catfile($destination,
							join('_',sprintf('%s%s',(File::Spec->splitpath($self->{sources}->[$count-1])||'root'),'.ufsdump'))
						);
		}

		# /usr/sbin/ufsrestore tbfy 64 /dump/backup/dylan/hostdumps/dylan_u03.ufsdump.level.0
		# /usr/sbin/ufsrestore i | r | R |  t  |  x  [abcdfhlmostvyLT]
		#     [archive_file]  [factor]  [dumpfile] [n] [label] [timeout] [
		#     filename...]
		my $command_to_execute = sprintf('%s tbfy %s %s',
									$self->{system_commands}->{ufsrestore},
									64,
									$destination
								);
		my ($exit_status, $signal_num, $dumped_core, $stdout, $stderr)
				= $self->execute_system_command($command_to_execute);

		# /bin/mt -f /dump/backup/dylan/hostdumps/dylan_u03.ufsdump.level.0 fsf 1
		# mt [-f tapename] command... [count]
		$command_to_execute = sprintf('%s -f %s %s %s',
									$self->{system_commands}->{mt},
									$destination,
									'fsf',
									1
								);
		($exit_status, $signal_num, $dumped_core, $stdout, $stderr)
				= $self->execute_system_command($command_to_execute)
						unless $count == @{$self->{sources}};
	}

	# Done
}










sub tar_archive_handler {
	my $self = shift;

	# Check we have the right commands before we do anything
	$self->must_have_commands(qw(tar));

	# Compression commands
	my ($compress,$uncompress);
	if ($self->{bzip2}) {
		die(5,"Cannot file supporting compression binaries") unless
				$self->must_have_commands(qw(bzip2 bunzip2));
		$compress = $self->{system_commands}->{bzip2};
		$uncompress = $self->{system_commands}->{bunzip2};

	} elsif ($self->{gzip}) {
		die(6,"Cannot file supporting compression binaries") unless
				$self->must_have_commands(qw(gzip gunzip));
		$compress = $self->{system_commands}->{gzip};
		$uncompress = $self->{system_commands}->{gunzip};

	} elsif ($self->{compress}) {
		die(7,"Cannot file supporting compression binaries") unless
				$self->must_have_commands(qw(compress uncompress));
		$compress = $self->{system_commands}->{compress};
		$uncompress = $self->{system_commands}->{uncompress};
	}

	# Debug
	TRACE("Compression set to use '$compress' and '$uncompress'\n")
				if $compress || $uncompress;

	# Ensure destination is a file
	die(8,"Destination must be a filename") if -d $self->{destination};

	# tar  c  [  bBeEfFhiklnopPqvwX@  [0-7]]   [block]   [tarfile]
	#      [exclude-file]  {-I include-file  |  -C directory  |  file |
	#      file} ...
	my $command_to_execute = sprintf('%s %s%s %s %s %s %s',
									$self->{system_commands}->{tar},
									$self->{verbose} ? 'v' : '',
									'cf',
									($compress ? '-' : $self->{destination}),
									join(' ', @{$self->{sources}}),
									($compress ? "|$compress " : ''),
									($compress ? ">$self->{destination}" : ''),
								);
	my ($exit_status, $signal_num, $dumped_core, $stdout, $stderr)
				= $self->execute_system_command($command_to_execute);

	# Skip verification stage
	return if $self->{'no-verify'};

	# Verify each source
	$command_to_execute = sprintf('%s %s %s%s %s',
									($uncompress ? "$uncompress -c $self->{destination}|" : ''),
									$self->{system_commands}->{tar},
									$self->{verbose} ? 'v' : '',
									'tf',
									($uncompress ? '-' : $self->{destination})
								);
	($exit_status, $signal_num, $dumped_core, $stdout, $stderr)
				= $self->execute_system_command($command_to_execute);

	# Done
}










###############################################################################
# Helper flange

# Execute a command and capture the output and return value
sub execute_system_command {
	my $self = shift;
	my $command_to_execute = shift;

	# Flangify the command a little to redirect stdout and stderr since we
	# know we will get chuffing loads of output in verbose output for actual
	# backup commands on medium to large filesystems
	my @args = split(/\s+/,$command_to_execute);

	my $stdout_filename;
	unless ($command_to_execute =~ />/) {
		$stdout_filename = $self->temporary_filename();
		push @args, sprintf('>%s',$stdout_filename);
		$self->log("Logging STDOUT for command [$command_to_execute] to $stdout_filename\n") unless $self->{quiet};;
	} else {
		$self->log2("Command [$command_to_execute] is already redirecting STDOUT; not redirecting again\n");
	}

	my $stderr_filename;
	unless ($command_to_execute =~ /2>/) {
		$stderr_filename = $self->temporary_filename();
		push @args, sprintf('2>%s',$stderr_filename);
		$self->log("Logging STDERR for command [$command_to_execute] to $stderr_filename\n") unless $self->{quiet};
	} else {
		$self->log2("Command [$command_to_execute] is already redirecting STDERR; not redirecting again\n");
	}

	# Execute the command
	unless ($self->{'dry-run'}) {
		system(join(' ',@args));
	} else {
		$self->log("Skipping actual execution of command [$command_to_execute]");
	}
	my $exit_value  = $? >> 8;
	my $signal_num  = $? & 127;
	my $dumped_core = $? & 128;

	# Output unless quiet
	$self->log("EXIT: exit_value='$exit_value',".
			" signal_num='$signal_num',".
			" dumped_core='$dumped_core'\n") unless $self->{quiet};

	# Verbose output
	$self->dump_file_to_output($stdout_filename, sub { $self->{verbose} && $self->log($_); })
			if $self->{verbose} && $stdout_filename;

	# Error output unless very quiet
	$self->dump_file_to_output($stderr_filename, sub { $self->log2($_); })
			unless $self->{'very-quiet'} || !$stderr_filename;

	# Junk the files
	unless ($self->{'keep-logs'}) {
		if ($stdout_filename) {
			$self->log("Removing temporary STDOUT output log file [$stdout_filename]") if $self->{verbose};
			unlink $stdout_filename;
		}
		if ($stderr_filename) {
			$self->log("Removing temporary STDERR output log file [$stderr_filename]") if $self->{verbose};
			unlink $stderr_filename;
		}
	}

	return ($exit_value, $signal_num, $dumped_core, $stdout_filename, $stderr_filename);
}

# Dump file to output
sub dump_file_to_output {
	my $self = shift;
	my $filename = shift;
	my $action = shift;

	my $fh = new FileHandle();
	if ($fh->open($filename)) {
		while (<$fh>) {
			&{$action};
		}
		$fh->close();
	}
}

# Temporary filename
sub temporary_filename {
	my $self = shift;

	# This is abstracted in to a seperate method
	# because some older versions of File::Spec don't
	# seem to support tmpdir() which File::Temp relys
	# on for the tmpnam() function. It may be necessary
	# to hand craft some of this in manual kruft on
	# some older platforms and versions of Perl etc.
	my ($fh,$filename) = File::Temp::tempfile('bakXXXXX',
								DIR => File::Spec->tmpdir(),
								SUFFIX => '.tmp'
							);
	close($fh);

	return $filename;
}

# Close stderr
sub close_stderr {
	my $self = shift;
	return if $self->{close_stderr};
	close(STDERR) || die "Can't close STDERR: $!";
	open(STDERR, sprintf('>%s',File::Spec->devnull())) || die "Can't dup STDERR: $!";
	$self->{close_stderr}++;
}

# Close stdout
sub close_stdout {
	my $self = shift;
	return if $self->{close_stdout};
	close(STDOUT) || die "Can't close STDOUT: $!";
	open(STDOUT, sprintf('>%s',File::Spec->devnull())) || die "Can't redirect STDOUT: $!";
	$self->{close_stdout}++;
}

# Open stderr
sub open_stderr {
	my $self = shift;
	close(STDERR) || die "Can't close STDERR: $!";
	open(STDERR, ">&REAL_STDERR") || die "Can't restore STDERR: $!";
	$self->{close_stderr}++;
}

# Open stdout
sub open_stdout {
	my $self = shift;
	close(STDOUT) || die "Can't close STDOUT: $!";
	open(STDOUT, ">&REAL_STDOUT") || die "Can't restore STDOUT: $!";
	$self->{close_stdout}++;
}

# Init
sub init {
	my $class = shift;

	my $self = {
			hostname => (POSIX::uname())[1],
			config => File::Spec->rel2abs(
							File::Spec->catfile('etc','backup.conf'),
							File::Spec->rootdir()
						),
		};
	$self->{config} =~ s|^//|/|; # File::Spec::Cygwin bug

	bless $self, $class;
	return $self;
}

# Read in the config
sub read_config_file {
	my $self = shift;
	my $config_file = shift;

	# Barf and die if there's no configuration file!
	die(9,"Configuration file $config_file does not exist\n")
			unless -e $config_file;

	# Define default configuration values
	my %default = (
					vfstab_exclude	=> File::Spec->rel2abs(
								File::Spec->catfile('etc','vfstab.exclude'),
								File::Spec->rootdir(),
							),
					archivehandler	=> 'ufsdump',
			);
	$default{vfstab_exclude} =~ s|^//|/|; # File::Spec::Cygwin bug

	# Read config file
	my $conf = new Config::General(
					-ConfigFile				=> $config_file,
					-LowerCaseNames			=> 1,
					-UseApacheInclude		=> 1,
					-IncludeRelative		=> 1,
					-DefaultConfig			=> \%default,
					-MergeDuplicateBlocks	=> 1,
					-AllowMultiOptions		=> 1,
					-MergeDuplicateOptions	=> 1,
					-AutoTrue				=> 1,
			);
	my %config = $conf->getall;

	for (keys %config) {
		$self->{$_} = $config{$_} unless exists $self->{$_};
	}
}

# Get upset and up-chuck if we don't have these commands
sub must_have_commands {
	my $self = shift;
	my @commands = @_;

	for my $command (@commands) {
		unless (exists $self->{system_commands}->{$command}) {
			die(10,"Could not find required system command '$command'");
		}
	}

	return 1;
}

# Find full path and filenames of system commands
sub find_system_commands {
	my $self = shift;
	my @commands = @_;

	my $system_commands = {};
	my @paths = File::Spec->path();
#	my @paths = $ENV{PATH} ? split(/(;|:|\s+)/,$ENV{PATH}) :
#				$^O ne 'MSWin32' ? qw(/bin /usr/bin /sbin /usr/sbin) : undef;
	@paths = split(/(:|\s+)/,$self->{path}) if exists $self->{path};
	for my $command (@commands) {
		for my $path (@paths) {
			my $fqcn = File::Spec->catfile($path,$command);
			if (-f $fqcn && -x $fqcn) {
				$system_commands->{$command} = $fqcn;
				last;
			}
		}
	}

	return $system_commands;
}

# Get a list of all of the filesystems which we *want* to process
sub gather_filesystem_sources {
	my $self = shift;

	my $fs = new Sys::Filesystem;
	my @regular_filesystems = $fs->regular_filesystems();
	my @mounted_filesystems = $fs->mounted_filesystems();
	my @vfstab_excludes = $self->read_vfstab_exclude($self->{vfstab_exclude});
	DUMP('@vfstab_excludes',\@vfstab_excludes);

	my @sources = ();
	for my $fs (@regular_filesystems) {
		unless (grep({$fs eq $_} @vfstab_excludes)) { # Check it's not excluded
			if (grep({$fs eq $_} @mounted_filesystems)) { # And it's mounted
				push @sources, $fs;
			}
		}
	}

	return @sources;
}

# Read in the vfstab_exclude file
sub read_vfstab_exclude {
	my $self = shift;
	my $file = shift || die(11,"File not specified where expected");
	
	my @excludes = ();
	if (-e $file) {
		my $vfstab_exclude = new FileHandle;
		if ($vfstab_exclude->open($file)) {
			while (<$vfstab_exclude>) {
				next if /^\s*\#/;
				s/([^\\])\#.*/$1/;
				if (/^\s*(.+)\s*$/) {
					push @excludes, $1;
				}
			}
			$vfstab_exclude->close();
		} else {
			die(12,"Unable to open $file: $!");
		}
	} else {
		return @excludes;
	}

	return @excludes;
}

# Read the command line options
sub process_command_line_options {
	my $self = shift;
	my $target = shift;

	my $foo = 'config=s exclude=s exclude-from=s include=s include-from=s
				help h>help verbose v>verbose quiet dry-run n>dry-run
				very-quiet one-filesystem-only x>one-filesystem-only version
				trace t>trace deep-trace T>deep-trace gzip z>gzip bzip j>bzip
				recursive r>recursive c>config compress Z>compress tar R>tar
				ufsdump U>ufsdump keep-logs k>keep-logs no-verify s>no-verify';

	Getopt::Mixed::init($foo);
	while (my ($k, $v) = Getopt::Mixed::nextOption()) {
		$v = 1 if !defined $v;
		$target->{lc($k)} = $v;
	}
	Getopt::Mixed::cleanup();

	return $target;
}

# Prefix with syslog style time stamp
sub timestamp {
	my $self = shift;
	my $time = time;

	#Sep 26 19:00:01 lilacup psmon[26926]:
	my @mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);

	return sprintf('%s %d %d:%02d:%02d %s %s[%d]: %s',
							$mon[$mon], $mday, $hour, $min, $sec,
							$self->{hostname},
							(File::Spec->splitpath($main::PROGRAM_NAME))[2],
							(caller(1))[2],
							$_
						);
}

# Print a timestamped message to STDERR
sub log2 {
	my $self = shift;
	my @vals = @_;
	for (@vals) {
		chomp;
		print STDERR ($self->timestamp($_)."\n");
	}
}

# Print a timestamped message to STDOUT
sub log {
	my $self = shift;
	my @vals = @_;
	for (@vals) {
		chomp;
		print STDOUT ($self->timestamp($_)."\n");
	}
}

# Take copies of the file descriptors
BEGIN {
	open(REAL_STDOUT, ">&STDOUT") || die "Can't open REAL_STDOUT: $!";
	open(REAL_STDERR, ">&STDERR") || die "Can't open REAL_STDERR: $!";
}

# Ensure that we put all the filehandle back right
END {
	# Close the redirected filehandles
	close(STDERR) || die "Can't close STDERR: $!";
	close(STDOUT) || die "Can't close STDOUT: $!";

	# Restore STDOUT and STDERR
	open(STDERR, ">&REAL_STDERR") || die "Can't restore STDERR: $!";
	open(STDOUT, ">&REAL_STDOUT") || die "Can't restore STDOUT: $!";

	# Avoid leaks by closing the independent copies
	close(REAL_STDOUT) || die "Can't close REAL_STDOUT: $!";
	close(REAL_STDERR) || die "Can't close REAL_STDERR: $!";
}

# Overload perl's die so that we always return a unique exit code
sub die {
	my ($retval,@messages) = @_;

	unless (@messages) {
		@messages = ($retval);
		$retval = 1;
	}
	my $message = join(' ',@messages);
	chomp $message;

	warn "FATAL[$retval]: $message\n";
	exit $retval;
}

sub TRACE {
	return unless DEBUG || $self->{trace} || $self->{'deep-trace'};
	warn(shift());
}

sub DUMP {
	return unless DEBUG || $self->{trace} || $self->{'deep-trace'};
	eval {
		require Data::Dumper;
		warn(shift().': '.Data::Dumper::Dumper(shift()));
	}
}










###############################################################################
# End

exit;

1;










###############################################################################
# POD

=pod

=head1 NAME

backup.pl - Generic extendable backup script



=head1 VERSION

$Revision$



=head1 SYNOPSIS

    Usage: backup.pl [OPTION]... DEST
      or   backup.pl [OPTION]... SRC [SRC]... DEST
    
    Options
     -v, --verbose               increase verbosity
     -q, --quiet                 decrease verbosity
     -Q, --very-quiet            surpress all output including errors
     -t, --trace                 output trace information
     -T, --deep-trace            output deep trace information
     -n, --dry-run               show what would have been transferred
     -k, --keep-logs             keep temporary logs from system commands
     -s, --no-verify             skip backup verification stage
     -U, --ufsdump               use the built-in ufsdump archive handler
     -R, --tar                   use the built-in tar archive handler
     -Z, --compress              compress file data using compress
     -z, --gzip                  compress file data using gzip
     -j, --bzip                  compress file data using bzip2
         --version               print version number
     -c, --config=FILE           specify alternate backup.pld.conf file
     -h, --help                  show this help screen

=cut

#     -r, --recursive             recurse into directories
#     -x, --one-file-system       don't cross filesystem boundaries
#         --exclude=PATTERN       exclude files matching PATTERN
#         --exclude-from=FILE     exclude patterns listed in FILE
#         --include=PATTERN       don't exclude files matching PATTERN
#         --include-from=FILE     don't exclude patterns listed in FILE

=pod

=head1 DESCRIPTION

backup.pl is a wrapper script to backup files and/or entire filesystems to
a file, directory or backup device. It is designed to be as portable and
flexible as possible to allow easy drop-in backup solutions, beit using a
configuration file, command line options or a combination of the two.

Use of a configuration file allows enhanced functionality over purely command
line use since it provides an interface to load plug-ins for different
archival methods instead of using the built-in default tar and ufsdump
handlers.

If no source is specified on the command line or in a comfiguration file,
backup.pl will attempt to backup all "sensible" filesystems to the destination
directory using whatever archival handler is specified, (ufsdump by default).
Exclude files will be honored during this default behaviour.



=head1 OPTIONS

backup.pl uses the Getopt::Mixed options package. Many of the command line
options have two variants, one short and one long. These are shown below,
separated by commas. Some options only have a long variant. The '=' for
options that take a parameter is optional; whitespace can be used instead.

=over 4

=over 4

=item -v, --verbose

This option increases the amount of information you are given during the
backup procedure. By default backup.pl works silently. A single -v will give
you information about what files are being archived and a brief summary at the
end. For debug information use the -t or -T flags.


=item -q, --quiet

This option decreases the amount of information you are given during the backup
procedure, notably suppressing information messages from the archival handlers.
This flag is useful when invoking backup.pl from cron.


=item -Q, --very-quiet

This option is similar to the -q flag but surpresses ALL output, including
all error messages. Use of this option should be avoided whenever possible.


=item -t, --trace

This option increased the amount of information you are given during the
wrapper processing by using the Tracing.pm module.


=item -T, --deep-trace

This option increased the amount of information you are given during the
wrapper processing by using the Tracing.pm module in deep tracing mode.


=item -k, --keep-logs

This option will stop deletion of the temporary output log files which are
created during execution of system commands. These files are normally deleted
right after the command and logging of any output to STDOUT/STDERR has
completed. The files are created with the filemask bakXXXXX.tmp in the system
temporary file directory; typically /tmp under a POSIX based system or C:\TMP
under Windows.


=item -n, --dry-run

This tells backup.pl to not do any disk writes, instead it will just report the
actions it would have taken.


=item -Z, --compress

With this option, backup.pl compresses any data from the files that it sends to
the destination target. This option is useful when archiving to a file when
space is at a premium or when writing to a drvice which does not support
hardware compression. The compression method used is the same method that
compress uses.


=item -z, --gzip

With this option, backup.pl compresses any data from the files that it sends to
the destination target. This option is useful when archiving to a file when
space is at a premium or when writing to a drvice which does not support
hardware compression. The compression method used is the same method that gzip
uses.


=item -j, --bzip

With this option, backup.pl compresses any data from the files that it sends to
the destination target. This option is useful when archiving to a file when
space is at a premium or when writing to a drvice which does not support
hardware compression. The compression method used is the same method that bzip2
uses.

=cut

#=item -r, --recursive
#
#This tells backup.pl to backup directories recursively. If you don't specify
#this then backup.pl won't backup directories at all.
#
#
#=item -x, --one-file-system
#
#This tells backup.pl not to cross filesystem boundaries when recursing. This is
#useful for archiving the contents of only one filesystem.
#
#
#=item --exclude=PATTERN
#
#This option allows you to selectively exclude certain files from the list of
#files to be archived. This is most useful in combination with a recursive
#backup.
#
#You may use as provide multiple patterns seperated by a comma (,) delimiter.
#
#See the section on exclude patterns for information on the syntax of this
#option.
#
#
#=item --exclude-from=FILE
#
#This option is similar to the --exclude option, but instead it adds all exclude
#patterns listed in the file FILE to the exclude list. Blank lines in FILE and
#lines starting with ';' or '#' are ignored.
#
#
#=item --include=PATTERN
#
#This option tells backup.pl to not exclude the specified pattern of filenames.
#This is useful as it allows you to build up quite complex exclude/include rules
#
#See the section of exclude patterns for information on the syntax of this
#option.
#
#
#=item --include-from=FILE
#
#This specifies a list of include patterns from a file.

=pod

=item --version

Print the version number and exit


=item -c, --config=FILE

This specifies an alternate config file than the default. The default is
/etc/backup.conf.


=item -h, --help

Print this help page describing the options available

=back

=back

=cut

#=head1 EXCLUDE PATTERNS
#
#The exclude and include patterns specified to backup.pl allow for flexible
#selection of which files to backup and which files to skip.
#
#backup.pl builds an ordered list of include/exclude options as specified on the
#command line. When a filename is encountered, backup.pl checks the name
#against each exclude/include pattern in turn. The first matching pattern is
#acted on. If it is an exclude pattern, then that file is skipped. If it is an
#include pattern then that filename is not skipped. If no matching
#include/exclude pattern is found then the filename is not skipped.
#
#Note that when used with -r, every subcomponent of every path is visited from
#top down, so include/exclude patterns get applied recursively to each
#subcomponent.
#
#The patterns can take several forms. The rules are:
#
#=over 4
#
#=item *
#
#if the pattern starts with a / then it is matched against the start of the
#filename, otherwise it is matched against the end of the filename.  Thus "/foo"
#would match a file called "foo" at the base of the tree. On the other hand,
#"foo" would match any file called "foo" anywhere in the tree because the
#algorithm is applied recursively from top down; it behaves as if each path
#component gets a turn at being the end of the file name.
#
#=item *
#
#if the pattern ends with a / then it will only match a directory, not a
#file, link or device.
#
#=item *
#
#if the pattern contains a perl style regular expression metacharacter then the
#pattern will be applied to the full path and filename instead of the normal
#resursive top down method. You will need to escape metacharacters if your
#provide them on the command line.
#
#=item *
#
#if the pattern contains a / (not counting a trailing /) then it is matched
#against the full filename, including any leading directory. If the pattern
#doesn't contain a / then it is matched only against the final component of the
#filename. Again, remember that the algorithm is applied recursively so "full
#filename" can actually be any portion of a path.
#
#=back
#
#Here are some exclude/include examples:
#
#=over 4
#
#=item *
#
#--exclude "\.o$" would exclude all filenames ending in *.o
#
#=item *
#
#--exclude "/foo" would exclude a file in the base directory called foo
#
#=item *
#
#--exclude "foo/" would exclude any directory called foo
#
#=item *
#
#--exclude "/foo/[^/]+/bar" would exclude any file called bar two levels below a
#base directory called foo
#
#=item *
#
#--exclude "/foo/.+/bar" would exclude any file called bar two or more levels
#below a base directory called foo
#
#=item *
#
#--include "/$,\.c$" --exclude ".*" would include all directories and C source
#files
#
#=item *
#
#--include "foo/$,foo/bar\.c" --exclude ".*" would include only foo/bar.c (the
#foo/ directory must be explicitly included or it would be excluded by the ".*")
#
#=back

=pod

=head1 CONFIGURATION FILE

The configuration file follows the standard Apache project configuration file
layout. (Plain text key value pairs in this instance). Command line options may
be provided in the configuration file (without the prefixing -- charachers).

Command line options will always take presedance over configuration file
options. If a command line option is not set, a configuration file option may
be loaded as the new default value to be used.

Additional options other than the normal command line options, which can be
used are as follows:

=over 4

=item vfstab_exclude

Define the path and filename of the vfstab_exclude filename to read when
scanning the filesystems for default backup sources. This will default to
/etc/vfstab.exclude.

=back



=head1 EXIT CODES

=over 4

=item Exit Value 2

You must specify a target destination.

=item Exit Value 3

Could not locate any valid sources.

=item Exit Value 4

ufsdump archive handler does not support compression.

=item Exit Value 5, 6 and 7

Cannot file supporting compression binaries, (bzip2, gzip and compress respectively).

=item Exit Value 8

Destination must be a filename.

=item Exit Value 9

Configuration file does not exist.

=item Exit Value 10

Could not find required system command.

=item Exit Value 11

File not specified when calling read_vfstab_exclude().

=item Exit Value 12

Unable to open the vfstab file.

=back

=head1 SEE ALSO

tar(1), ufsdump(1M), rsync(1)



=head1 TODO

All the coding.



=head1 BUGS

Probably.



=head1 AUTHOR

Nicola Worthington <nicolaworthington@msn.com>

http://www.nicolaworthington.com

$Author$

=cut










###############################################################################
# EOF

__DATA__

__END__

