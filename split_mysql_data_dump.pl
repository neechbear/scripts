#!/usr/bin/perl -w

use 5.6.1;
use strict;
use warnings;

my $file = $ARGV[0] || '';
die "Please specify a MySQL dump filename.\n" unless $file && -f $file;

my @header;
my $table = '';
my $lastline = '';
my $out;

open(FH,'<',$file) || die "Unable to open file '$file': $!\n";
while (local $_ = <FH>) {
	if (!$table && /^--\s*Dumping data for table/i && $lastline =~ /^--\s*$/) {
		pop @header;
		if (/^--\s*Dumping data for table \`(\S+)?\`/) { $table = $1; }
		$out = open_sql_file("$file.$table.sql",$out);
		print $out join('',@header);
		print $out $lastline;
		print $out $_;

	} elsif (!$table) {
		push @header, $_;

	} elsif (/^--\s*Dumping data for table \`(\S+)?\`/) {
		$table = $1;
		$out = open_sql_file("$file.$table.sql",$out);
		print $out join('',@header);
		print $out $lastline;
		print $out $_;

	} else {
		print $out $_;
	}

	$lastline = $_;
}
close(FH) || warn "Unable to close file '$file': $!\n";
close($out) if defined $out;

exit;

sub open_sql_file {
	my ($file,$fh) = @_;
	close($fh) if defined $fh;
	die "$file already exists; aborting!\n" if -e $file;
	open($fh,'>',$file) || die "Unable to open file '$file': $!\n";
	return $fh;
}

