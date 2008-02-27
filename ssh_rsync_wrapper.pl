#!/usr/bin/perl -w

use 5.8.0;
use strict;
use warnings;

use constant RSYNC_CMD => '/usr/bin/rsync';

# Since this script is called as a forced command, need to get the
# original rsync command given by the client.
my $cmd = '';
$cmd = $ENV{SSH_ORIGINAL_COMMAND};
$cmd = join(' ',@ARGV) if @ARGV;
fail("Environment variable SSH_ORIGINAL_COMMAND not set")
	unless defined($cmd) && $cmd =~ /\S+/;

# Split the command string to make an argument list, and remove the first
# element (the command name; we'll supply our own);
my @cmd_argv = split(/\s+/, $cmd);
fail("Account restricted: only rsync allowed ($cmd_argv[0])")
    unless $cmd_argv[0] eq 'rsync' || $cmd_argv[0] eq RSYNC_CMD;

# Ensure that --server is in the command line, to enforce running
# rsync in server mode.
my $server_mode = 0;
for my $arg (@cmd_argv) {
    if ($arg eq '--server') {
	$server_mode = 1;
	last;
    }
}

fail("Restricted; only server mode allowed")
	unless $server_mode;

shift(@cmd_argv);
exec(RSYNC_CMD, @cmd_argv);

exit;

sub fail {
    warn sprintf("%s: %s\n", $0, join(' ', @_));
    exit 1;
}

