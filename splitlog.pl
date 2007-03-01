#!/usr/bin/perl -w

use strict;
my %month = qw(Jan 01 Feb 02 Mar 03 Apr 04 May 05 Jun 06
			Jul 07 Aug 08 Sep 09 Oct 10 Nov 11 Dec 12);

my @t = localtime;
my $today = sprintf('%04d%02d%02d',$t[5]+1900,$t[4]+1,$t[3]);
my @logfiles = glob('*.log');

for my $logfile (@logfiles) {
	next if $logfile =~ /error/;
	open(LOG,'<',$logfile) || die "Unable to open $logfile: $!";
	my $lastout = '';
	my $open = 0;
	my ($read,$understood,$written) = (0,0,0);
	while (local $_ = <LOG>) {
		$read++;
		if (my ($dd,$mmm,$yyyy) = $_ =~ /\[(\d\d)\/([A-Za-z]{3})\/(\d{4})/) {
			$understood++;
			my $date = "$yyyy$month{$mmm}$dd";
			if ($lastout ne "$logfile-$date") {
				close(OUT) if $lastout;
				open(OUT,'>>',"$logfile-$date") || die "Unable to open $logfile-$date: $!";
				$open++;
			}
			print OUT $_;
			$written++ if $open;
			$lastout = "$logfile-$date";
		}
	}
	close OUT;
	if(rename($logfile,"$logfile.bak")) {
		rename("$logfile-$today",$logfile);
	}
	print "Validation:\n";
	printf("  %20s: %d lines\n",'Read',$read);
	printf("  %20s: %d lines\n",'Understood',$understood);
	printf("  %20s: %d lines\n",'Wrote',$written);
	my $a = `cat $logfile-???????? $logfile 2>/dev/null | wc -l`; chomp $a;
	printf("  %20s: %s lines\n",'Split files',$a);
	my $b = `cat $logfile.bak 2>/dev/null | wc -l`; chomp $b;
	printf("  %20s: %s lines\n\n","$logfile.bak",$b);
}


