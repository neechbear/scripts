#!/usr/bin/perl -w
############################################################
#
#   $Id$
#   nagios-reporter.pl
#
#   Copyright 2008 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################
# vim:ts=4:sw=4:tw=78

use 5.6.1;
use strict;
use warnings;
use Getopt::Std qw();
use Net::SMTP qw();
use LWP::UserAgent qw();
use Date::Manip qw();
use POSIX qw();
use vars qw($VERSION);

$VERSION = '0.01' || sprintf('%d', q$Revision: 1092 $ =~ /(\d+)/g);

my $opt = {
	t => 30,
	T => 'overnight',
	u => 'nagios-admin',
	p => 'password',
	};

$Getopt::Std::STANDARD_HELP_VERSION = 1;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
Getopt::Std::getopts('T:t:r:f:s:u:p:m:U:vh?', $opt);

(VERSION_MESSAGE() && exit) if defined $opt->{v};
(HELP_MESSAGE() && exit) if defined $opt->{h} || defined $opt->{'?'};

if (defined $opt->{T} && $opt->{T} !~ /^(overnight|daily|weekly|monthly)$/i) {
	HELP_MESSAGE("Invalid report type '$opt->{T}'.");
	exit 1;
}

if (!defined $opt->{m} || !defined $opt->{r} || !defined $opt->{f} || !defined $opt->{U}) {
	HELP_MESSAGE("Missing mandatory arguments.");
	exit 1;
}

my ($reportUrl,$subject) = get_report_url($opt->{T}, $opt->{U});
$subject = defined $opt->{s} && $opt->{s} =~ /\S+/ ? $opt->{s} : $subject;

warn "$reportUrl\n" if $ENV{DEBUG};
warn "$subject\n" if $ENV{DEBUG};

my $body = http_request($reportUrl, $opt->{u}, $opt->{p});
while ($body =~ m,(<link\s+rel=['"]stylesheet['"]\s+.*?href=['"](.+?)['"].*?>),imsg) { #'
	my ($link,$cssUrl) = ($1,$2);
	if ($cssUrl =~ m,^https?://,i) {
		# Supah!
	} elsif ($cssUrl =~ m,^/, && $opt->{U} =~ m,^(https?://.+?)/,) {
		$cssUrl = "$1$cssUrl";
	} else {
		$cssUrl = "$opt->{U}/$cssUrl";
	}

	my $css = http_request($cssUrl, $opt->{u}, $opt->{p});
	$body =~ s,$link,\n<style type="text/css">\n$css\n</style>\n\n,i;
}

sendmail(
	$opt->{r}, $opt->{f}, $subject, "$body\n",
	$opt->{t}, $opt->{m}
	);

exit;

sub http_request {
	my ($url,$user,$pass) = @_;
	die "Invalid or missing URL" unless defined $url && $url =~ /^https?\:\/\/\S+/;

	my $ua = LWP::UserAgent->new;
	$ua->agent("Nagios Report Generator $0 $VERSION ".$ua->agent);
	my $req = HTTP::Request->new(GET => $url);
	$req->authorization_basic($user, $pass);
	my $res = $ua->request($req);

	if ($res->is_success) {
		return $res->decoded_content;
	} else {
		die $res->status_line;
	}
}

sub sendmail {
	my ($to,$from,$subject,$body,$timeout,$server) = @_;
	die "Invalid recipient address"      unless defined $to      && $to =~ /\S+\@\S+/;
	die "Invalid sender address"         unless defined $from    && $from =~ /\S+\@\S+/;
	die "Invalid or empty email subject" unless defined $subject && $subject =~ /\S+/;
	die "Invalid or empty email body"    unless defined $body    && $body =~ /\S+/;
	die "Invalid SMTP timeout value"     unless defined $timeout && $timeout =~ /^\d+$/;
	die "Invalid mail server name"       unless defined $server  && $server =~ /^[a-z0-9\-\.\_]+$/;

	if ($ENV{DEBUG}) {
		warn "To: $to\n";
		warn "From: $from\n";
		warn "Subject: $subject\n";
		warn "Server: $server\n";
		warn "Timeout: $timeout\n";
	}

	my $smtp = Net::SMTP->new(
			Host    => $server,
			Hello   => (POSIX::uname)[1],
			Timeout => $timeout,
			Debug   => $ENV{DEBUG} ? 1 : 0,
		) || die "Failed to connect to mail server '$server'";

	$smtp->mail($from);
	$smtp->to($to);

	$smtp->data();
	$smtp->datasend("To: $to\n");
	$smtp->datasend("From: $from\n");
	$smtp->datasend("Subject: $subject\n");
	$smtp->datasend("MIME-Version: 1.0\n");
	$smtp->datasend("Content-type: multipart/mixed; boundary=\"zzXXzzXX-boundary-zzXXzzXX\"\n");
	$smtp->datasend("\n");
	$smtp->datasend("This is a multi-part message in MIME format.\n");
	$smtp->datasend("--zzXXzzXX-boundary-zzXXzzXX\n");
	$smtp->datasend("Content-type: text/html\n");
	$smtp->datasend("Content-disposition: inline\n");
	$smtp->datasend("Content-description: Nagios report\n");
	$smtp->datasend("Content-length: ".length($body)."\n");
	$smtp->datasend($body);
	$smtp->datasend("--zzXXzzXX-boundary-zzXXzzXX\n");
	$smtp->datasend("Content-type: text/plain\n");
	$smtp->datasend("Please read the attatchment\n");
	$smtp->datasend("--zzXXzzXX-boundary-zzXXzzXX--\n");
	$smtp->dataend();

	$smtp->quit;
}

sub HELP_MESSAGE {
	warn "@_\n\n" if @_;

        print qq{Syntax: nagios-reporter.pl [-r recipient] [-f sender] [-s "subject"]
                           [-U nagios URL] -u user] [-p password]
                           [-m mail server] [-t timeout] [-T type] [-h|-v]
    -T <type>       Overnight, daily, weekly or monthly report type (optional)
    -r <recipient>  Destination recipient email address
    -f <sender>     Sending from email address (reply to)
    -s "<subject>"  Email subject text (optional)
    -U <URL>        Nagios web interface URL
    -u <user>       Username to Nagios web interface URL (optional)
    -p <password>   Password to Nagios web interface URL (optional)
    -m <server>     SMTP mail server hostname
    -t <timeout>    SMTP mail server timeout in seconds (optional)
    -v              Display version information
    -h              Display this help\n};
}

# Display version
sub VERSION { &VERSION_MESSAGE; } 
sub VERSION_MESSAGE {
	print "$0 version $VERSION ".'($Id$)'."\n";
}


sub get_report_url {
	my ($type,$baseurl) = @_;
	die "Invalid or missing report type" unless defined $type;
	die "Invalid or missing Nagios URL" unless defined $baseurl && $baseurl =~ /^https?\:\/\/\S+/;
	$type = lc($type);

	my $subject;
	my %start;
	my %end = ( date => Date::Manip::ParseDate("today") );
	$end{date} =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
	@end{qw(day month year hour)} = ($3,$2,$1,0);

	# This should be run on the 1st of every month
	if ($type eq 'monthly') {
		$start{date} = Date::Manip::DateCalc("yesterday",1);
		$start{date} =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
		@start{qw(day month year hour)} = ('01',$2,$1,0);
		$subject = "Nagios alerts for month $start{month}/$start{year}";

	} elsif ($type eq 'weekly') {
		# This should be run on Friday, 9am
		$start{date} = Date::Manip::Date_PrevWorkDay("today",5);
		$start{date} =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
		@start{qw(day month year hour)} = ($3,$2,$1,9);
		$end{hour} = 9;
		$subject = "Nagios alerts for week ending $end{day}/$end{month}/$end{year}";

	} elsif ($type eq 'daily') {
		$start{date} = Date::Manip::Date_PrevWorkDay("today",1);
		$start{date} =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
		@start{qw(day month year hour)} = ($3,$2,$1,7);
		$end{hour}  = 7;
		$subject = "Nagios alerts for 24 hours $start{day}/$start{month}/$start{year} $start{hour}h to present";

	} else {
		$start{date} = Date::Manip::Date_PrevWorkDay("today",1);
		$start{date} =~ /(\d\d\d\d)(\d\d)(\d\d)(.*)/;
		@start{qw(day month year hour)} = ($3,$2,$1,17);
		$end{hour} = 9;
		$subject = "Nagios overnight alerts from $start{day}/$start{month}/$start{year} $start{hour}h to present";
	}

	my $url = sprintf('%s/cgi-bin/summary.cgi?report=1&displaytype=1&timeperiod=custom'.
		'&smon=%02d&sday=%02d&syear=%04d&shour=%02d&smin=00&ssec=00'.
		'&emon=%02d&eday=%02d&eyear=%04d&ehour=%02d&emin=00&esec=00'.
		'&hostgroup=all&servicegroup=all&host=all&alerttypes=3&statetypes=2&hoststates=3&servicestates=56&limit=500',
			$baseurl,
			$start{month}, $start{day}, $start{year}, $start{hour},
			$end{month},   $end{day},   $end{year},   $end{hour},
		);

	return ($url,$subject);
}


__END__

