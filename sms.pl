#!/usr/bin/perl -w

use 5.6.1;
use strict;
use warnings;

use LWP::UserAgent qw();
use HTTP::Request::Common qw(POST);
use File::HomeDir qw();
use Getopt::Std qw();

our $VERSION = '0.01';

my $opts = {};
Getopt::Std::getopt('vhu:p:t:o:fm:',$opts);
display_help(),exit if exists $opts->{h};
display_version(),exit if exists $opts->{v};

my $rcfile = File::HomeDir->my_home.'/.sms2emailrc';
write_rc($rcfile) unless -f $rcfile;
my $rcdata = read_rc($rcfile);

my %post = (
		username => $opts->{u} || $rcdata->{username} || '',
		password => $opts->{p} || $rcdata->{password} || '',
		to_num   => $opts->{t} || $rcdata->{to_num} || '',
		orig     => $opts->{o} || $rcdata->{orig} || '',
		flash    => $opts->{f} || $rcdata->{flash} || 0,
		message  => $opts->{m} || $rcdata->{message} || '',
	);

my %rcodes = (
		'AQSMS-NOAUTHDETAILS' => 'The username and password were not supplied',
		'AQSMS-AUTHERROR' => 'The username and password supplied were incorrect',
		'AQSMS-NOCREDIT' => 'The account specified did not have sufficient credit',
		'AQSMS-OK' => 'The message was queued successfully',
		'AQSMS-NOMSG' => 'No message or no destination number were supplied',
		'AQSMS-CREDIT' => '<number of messages>',
	);

my $post_type = 'http://';
my @post_servers = qw(gw1.sms2email.com gw11.sms2email.com
					gw2.sms2email.com gw22.sms2email.com");
my $post_path = '/sms/postmsg.php';
my $ua = LWP::UserAgent->new(agent => ($rcdata->{agent} || 'sms2email'));

foreach my $server (@post_servers) {
	my $resp = $ua->request(
			POST $post_type.$server.$post_path,
			Content_Type => 'form-data',
			Content => [ %post ]
		);
	my ($rcode) = $resp->content =~ /\b(AQSMS-\S+)\b/;
	if ($resp->is_success) {
		if ($rcodes{$rcode}) {
			printf("%s - %s\n",$rcode,$rcodes{$rcode});
		} else {
			printf("%s\n",$resp->content);
		}
		last;
	} else {
		warn sprintf("Error: %s%s%s - %s\n",
			$post_type,$server,$post_path,$resp->status_line);
	}
}

exit;

sub write_rc {
	my $file = shift;
	open(FH,'>',$file) || die "Unable to open file '$file': $!\n";
	while (local $_ = <DATA>) {
		print FH $_;
	}
	close(FH) || warn "Unable to close file '$file': $!\n";
}

sub read_rc {
	my $file = shift;
	my $rcdata = {};
	open(FH,'<',$file) || die "Unable to open file '$file': $!\n";
	while (local $_ = <DATA>) {
		chomp;
		next if /^\s*[#;]/ || /^\s*$/;
		if (/^\s*(\S+)\s+(.+?)\s*$/) {
			$rcdata->{$1} = $2;
		}
	}
	close(FH) || warn "Unable to close file '$file': $!\n";
	return $rcdata;
}

sub display_version {
	print qq{sms.pl version $VERSION\n};
}

sub display_help {
	print qq{Syntax: sms.pl [-v|-h] [-u <username>] [-p <password>]
               [-t <mobile number>] [-o originator] [-f] [-m "message"]
     -v            Display version information
     -h            Display this help
     -u username   Specify username to login to sms2email.com
     -p password   Specify password to login to sms2email.com
     -t number     Specify destination mobile phone number
     -o number     Specify originating mobile phone number
     -f            Send as a popup flash SMS message
     -m "message"  Specify the message to send
};
}

=pod

=head1 NAME

sms.pl - SMS Client for sms2email.com

=head1 SYNOPSIS

 Syntax: sms.pl [-v|-h] [-u <username>] [-p <password>]
                [-t <mobile number>] [-o originator] [-f] [-m "message"]
      -v            Display version information
      -h            Display this help
      -u username   Specify username to login to sms2email.com
      -p password   Specify password to login to sms2email.com
      -t number     Specify destination mobile phone number
      -o number     Specify originating mobile phone number
      -f            Send as a popup flash SMS message
      -m "message"  Specify the message to send

=head1 DESCRIPTION

This is a simple command line Perl client for the www.sms2email.com
SMS gateway service.

=head1 SEE ALSO

L<http://www.sms2email.com>, ~/.sms2emailrc

=head1 VERSION

$Id$

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

If you like this software, why not show your appreciation by sending the
author something nice from her
L<Amazon wishlist|http://www.amazon.co.uk/gp/registry/1VZXC59ESWYK0?sort=priority>? 
( http://www.amazon.co.uk/gp/registry/1VZXC59ESWYK0?sort=priority )

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut

__DATA__
# Default configuration file

# Username and password for www.sms2email.com
#username  myusername
#password  mypassword

# Recipient mobile number
to_num    447976295367

# Originating from
orig      +44738930000

# Send flash text message
flash     0

# Default message if none is specified
#message   Running late

# HTTP user agent
agent      sms2email perl client

# HTTP server posting URL
#url        https://gw1.sms2email.com/sms/postmsg.php

