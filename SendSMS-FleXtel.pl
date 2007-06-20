#!/usr/bin/perl -w
############################################################
#
#   $Id: SendSMS.pl,v 1.2 2007/02/07 13:55:43 nworthin Exp $
#   SendSMS.pl - Send SMS Text Messages via TextAnywhere.net's SOAP WebService
#
#   Copyright 2007 Nicola Worthington
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

#
# This version of SendSMS.pl has been modified for the 
# McAfee Antispam team. Modifications are
# Copyright (C) 2007 McAfee, Inc.  All rights reserved.
#

use constant FLEXTEL_NUMBER           => '07017726522';
use constant FLEXTEL_PIN              => '9991';
use constant TEXTANYWHERE_CLIENT_ID   => 'AU0621955';
use constant TEXTANYWHERE_CLIENT_PASS => 'toOl!uses';

############################################################
#
#       NO USER SERVICABLE PARTS BEYOND THIS POINT
#
############################################################






use 5.6.1;
use strict;
use warnings;
use SOAP::Lite qw();
use WWW::FleXtel 0.03 qw();
use Sys::Syslog qw(openlog closelog syslog);
use Storable qw(store retrieve);
use Getopt::Std qw();

our $VERSION = sprintf('%d.%02d', q$Revision: 1.2 $ =~ /(\d+)/g);
our $DEBUG ||= $ENV{DEBUG} ? 1 : 0;
(our $SELF = $0) =~ s/.*\///;

# Get command line options
my $opts = {};
Getopt::Std::getopt('vhd:o:m:',$opts);
display_help(),exit if exists $opts->{h};
display_version(),exit if exists $opts->{v};
display_help(),exit unless defined $opts->{d} && defined $opts->{o} && defined $opts->{m};

# Connect to syslog
openlog($SELF, 'cons,pid', 'user');

# Set defaults before we try FleXtel (incase there's an HTTP timeout)
my $sms_destination = $opts->{d};
my $flextel_destination = '??unknown??';
my $flextel_person = '';
my $sms_person = '';
$opts->{m} =~ s/\s+(CRITICAL|OK|OKAY|UNKNOWN|WARNING)\s+(CRITICAL|OK|OKAY|UNKNOWN|WARNING)\s*[\:\-]\s*/ $1. /;

# Get FleXtel number information
eval {
	my $flextel = WWW::FleXtel->new(
			number => FLEXTEL_NUMBER,
			pin    => FLEXTEL_PIN,
		);
	my $flextel_phonebook = $flextel->get_phonebook;
	$flextel_destination = $flextel->get_destination || '??unknown??';
	($flextel_person) = grep(/\S/, map { $_->{title} if defined $_ && $_->{number} eq $flextel_destination } @{$flextel_phonebook});
	$sms_destination = $flextel_destination =~ /^(\+447|07)/ ? $flextel_destination : $opts->{d};
	($sms_person) = grep(/\S/, map { $_->{title} if defined $_ && $_->{number} eq $sms_destination } @{$flextel_phonebook});
};

# Complain if there's an error
syslog('err','An error occured while trying to query FleXtel: %s',join(' ',split(/[\r\n]+/,$@))) if $@;

# Log what SMS we're sending
syslog('info',"FleXtel number %s is directed to %s (%s). FleXtel destination %s a mobile; sending SMS from '%s' to %s (%s): '%s'",
		FLEXTEL_NUMBER, $flextel_destination, ($flextel_person || 'not in phonebook'),
		( $flextel_destination =~ /^(\+447|07)/ ? 'is' : 'is not' ),
		$opts->{o}, $sms_destination, ($sms_person || 'not in phonebook'), $opts->{m},
	);

# Prepare to send the SMS
my $lastError = '';
my $returnCode = returnCode();
my $soapCfg = {
		wsdl   => 'http://ws.textanywhere.net/ta_SMS.asmx?wsdl',
		proxy  => 'http://ws.textanywhere.net/ta_SMS.asmx',
		uri    => 'http://ws.textanywhere.net/TA_WS',
	};

# Try and send an SMS
my $rtn = SendSMS($soapCfg,{
		'Client_ID'    => TEXTANYWHERE_CLIENT_ID,   # (str) Provided by TextAnywhere
		'Client_Pass'  => TEXTANYWHERE_CLIENT_PASS, # (str) Provided by TextAnywhere
		'Client_Ref'   => 'Client_Ref',  # (str) Send a Client reference of your choice that you will use with SMSstatus to get delivery reports
		'Billing_Ref'  => 'Billing_Ref', # (str) Send a billing reference of your choice for future reference.
		'Connection'   => 2,             # (int) 1- Simulator(No SMS is sent). 2-Enterprise SMS. 3-Premium SMS
		'Originator'   => $opts->{o},    # (str) Formated number with a + e.g. +4478945612 or 11 charaters
		'OType'        => 1,             # (int) 0- the originator mus be a phone number. 1-the orginator can be 11 characters e.g "hello"
		'Destination'  => $sms_destination, # (str) Formated number with a + e.g. +4478945612
		'Body'         => $opts->{m},    # (str) Text of you message
		'SMS_Type'     => 0,             # (int) 0- Normal SMS 1-Auto Open SMS, the message is displayed directly on the screen
		'SMS_encoding' => 0,             # (int) not in use at the moment. Must be set to 0
	});

# Print status
my $status = $rtn == 1  ? "Sent SMS message '$opts->{m}' to $sms_destination ($sms_person) okay\n"
			: exists $returnCode->{SendSMS}->{$rtn}
			? "Failed to send SMS message '$opts->{m}' to $sms_destination ($sms_person): $returnCode->{SendSMS}->{$rtn}\n"
			: "Failed to send SMS message '$opts->{m}' to $sms_destination ($sms_person): $lastError\n";

syslog('info',$status);
closelog();
exit;


# https://ws.textanywhere.net/web/Documents/TextAnywhere%20Developer%20Reference%20Guide.pdf

sub SendSMSEx           { &ExecuteSOAP; }
sub SendSMS             { &ExecuteSOAP; }
sub DeleteReply         { &ExecuteSOAP; }
sub CheckNumber         { &ExecuteSOAP; }
sub ServiceTest         { &ExecuteSOAP; }
sub SMSStatusEx         { &ExecuteSOAP; }
sub GetTextInboundXML   { &ExecuteSOAP; }
sub GetReply            { &ExecuteSOAP; }
sub FormatNumber        { &ExecuteSOAP; }
sub GetTextInbound      { &ExecuteSOAP; }
sub SMSStatus           { &ExecuteSOAP; }
sub GetReplyByClientRef { &ExecuteSOAP; }


sub display_help {
	print qq{$SELF [-v|-h|-d <destination> -o <originator> -m "<message>"]
       -v                 Display version information
       -h                 Display this help
       -d <destination>   Specify default destination phone number
       -o <originator>    Specify message originator
       -m "<message>"     Specify the SMS message body
};
}


sub display_version {
	print "$SELF version $VERSION\n";
}


sub ExecuteSOAP {
	my ($soapCfg,$msgParams) = @_;
	($soapCfg->{method} = (caller(1))[3]) =~ s/.*:://;

	DUMP('$soapCfg',$soapCfg);
	DUMP('$msgParams',$msgParams);

	my $soap = SOAP::Lite->new(
			uri => $soapCfg->{uri},
			proxy => $soapCfg->{proxy},
			autotype => 0,
			on_action => sub { join '/', $soapCfg->{uri}, $_[1] },
		);

	$soap->service($soapCfg->{wsdl}) if $soapCfg->{wsdl};

	my $method = SOAP::Data->name($soapCfg->{method})->attr({xmlns => $soapCfg->{uri}});
	my $resp = $soap->call($method => map {
				SOAP::Data->name($_ => $msgParams->{$_})
			} keys %{$msgParams}
		);

	DUMP('$resp->result',$resp->result);
	if ($resp->fault) {
		TRACE($resp->faultstring);
		$lastError = $resp->faultstring;
	}

	return $resp->result;
}


sub TRACE {
	return unless $DEBUG;
	warn(shift());
}

sub DUMP {
	return unless $DEBUG;
	eval {
		require Data::Dumper;
		no warnings 'once';
		local $Data::Dumper::Indent = 2;
		local $Data::Dumper::Terse = 1;
		warn(shift().': '.Data::Dumper::Dumper(shift()));
	}
}


sub returnCode {
	my $returnCode = {
		SendSMSEx => {
			1   => 'SMS Sent',
			2   => 'Authentication failed: Account not found',
			22  => 'Authentication failed: Your account is currently stopped',
			3   => 'SMS failed',
			31  => 'SMS failed: Insufficient message credits on your account',
			311 => 'SMS failed: This Connection does not exist',
			32  => 'SMS failed: Originator format not recognised',
			321 => 'SMS failed: OType invalid',
			33  => 'SMS failed: Destination(s) format not recognised',
			34  => 'SMS failed: Reply_Type invalid or Reply_Data empty',
			35  => 'SMS failed: Client_Ref too long or empty (maximum 50 characters)',
			36  => 'SMS failed: Billing_Ref too long or empty (maximum 50 characters)',
			37  => 'SMS failed: Body too long or empty (maximum 160 characters)',
			38  => 'SMS failed: Wrong message type',
			39  => 'SMS failed: Wrong message encoding',
		},
		SMSStatusEx => {
			2   => 'Authentication failed: account not found',
			22  => 'Authentication failed: account is currently suspended',
			4   => 'Delivery status request failed: one or more parameters are too long or empty (maximum 50 characters)',
			40  => 'Client_Ref parameter does not exist',
			41  => 'Message being processed by TextAnywhere system',
			43  => 'Message has been rejected',
			45  => 'Message has been delivered to the handset',
			46  => 'Failed: the message could not be delivered and will not be retried',
			47  => 'Message has been queued by the operator (recipient mobile phone may be switched off or out of service)',
			48  => 'Delivered to the network with no reports (message likely to have expired, as phone not switched on or out of service)',
			49  => 'Queued on TextAnywhere gateway',
			60  => 'Number not recognised',
			61  => 'Number contained in Opt-out List, message not sent',
		},
		DeleteReply => {
			0   => 'Message deletion failed',
			1   => 'Successful message(s) deletion',
		},
		SMSStatus => {
			2   => 'Authentication failed: Account not found',
			22  => 'Authentication failed: Your account is currently stopped',
			4   => 'Delivery status request failed',
			40  => 'Client_Ref does not exist',
			41  => 'Message being processed',
			42  => 'Message has been accepted',
			43  => 'Message has been rejected',
			44  => 'Message has been queued by the operator (recipient mobile phone may be switched off)',
			45  => 'Message has been delivered',
			46  => 'Failed: the message could not be delivered and will not be retried',
			47  => 'Acknowledged by the network',
			48  => 'Delivered to the network with no reports (message likely to have expired, as phone not switched on or out of service)',
			49  => 'Queued on TextAnywhere gateway',
			50  => 'Number not recognised',
			51  => 'Number Opted-Out, message not sent',
		},
	};
	$returnCode->{SendSMS} = $returnCode->{SendSMSEx};
	return $returnCode;
}


__END__


