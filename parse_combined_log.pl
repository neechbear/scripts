#!/usr/bin/perl -w
# vim:ts=4:sw=4:tw=78

use strict;
use Data::Dumper;
use vars qw($VERSION);
$VERSION = sprintf('%d.%02d', q$Revision: 1.1 $ =~ /(\d+)/g);

my @files = ();
for (@ARGV) {
	die "$_ does not exist; aborting\n" unless -e $_;
	die "$_ is not a file; aborting\n" unless -f $_;
	die "$_ is not readable; aborting\n" unless -r $_;
	push @files, $_;
}
die "Syntax: $0 <log files>\n" unless @files > 0;

my %errors;
for my $file (@files) {
	my ($port) = $file =~ /\bapache_log_(\d+)\b/;
	open(LOG,"<$file") || die "Unable to open file handle FH for file '$file': $!";
	while (my $line = <LOG>) {
		my $lref = process_line($line);
		if ($lref->{status} >= 400) {
			$errors{"$lref->{status} $lref->{request_file} $lref->{referer}"}++;
		}
	}
	close(LOG) || warn "Unable to close file handle for file '$file': $!";
}

for (sort { $errors{$b} <=> $errors{$a} } keys %errors) {
	print "$_ $errors{$_}\n";
}

sub process_line {
	local $_ = shift;
	my %lref;

	if ($_ =~ /^(.+?(\d+)?):(.+)$/) {
		$lref{log_filename} = $1;
		$lref{log_filename_port} = $2;
		$_ = $3;
	}

	@lref{qw(remote_host remote_logname remote_user time raw_request
			request_method request status bytes_sent referer user_agent
			process_id serve_secs)} = $_ =~ m!^
		(\S+)\s+				# remote_host
		(\S+)\s+				# remote_logname
		(\S+)\s+				# remote_user
		\[(\d\d/[A-Z][a-z][a-z]/\d\d\d\d:\d\d:\d\d:\d\d.*?)\]\s+	# time
		"(([A-Z]+)\s+(.*?[^\\]))"\s+	# request
		(\d+)\s+				# status
		(\d+)\s+				# bytes_sent
		"(.*?[^\\])"\s+			# referer
		"(.*?[^\\])"\s+			# user_agent
		(\d+)\s+				# process_id
		(\d+)					# serve_secs
			\s*$!x;

	if ($lref{request} =~ m/^(.+)\s+(HTTP\/1\.[01])$/) {
		$lref{request} = $1;
		$lref{server_protocol} = $2;
	} else {
		$lref{server_protocol} = '';
	}

	if ($lref{request} =~ m/^(.+?)\?(.+)$/) {
		$lref{request_file} = $1;
		$lref{query_string} = $2;
	} else {
		$lref{request_file} = $lref{request};
		$lref{query_string} = '';
	}

	return \%lref;
}

__END__

