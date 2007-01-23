#!/usr/bin/perl -w
############################################################
#
#   $Id: SendSMS.pl 866 2006-12-24 17:02:07Z nicolaw $
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

use 5.6.1;
use strict;
use warnings;
use SOAP::Lite qw();

our $VERSION = sprintf('%d.%02d', q$Revision: 1.11 $ =~ /(\d+)/g);
our $DEBUG ||= $ENV{DEBUG} ? 1 : 0;
(our $SELF = $0) =~ s/.*\///;

my $soapCfg = {
		wsdl   => 'http://ws.textanywhere.net/ta_SMS.asmx?wsdl',
		proxy  => 'http://ws.textanywhere.net/ta_SMS.asmx',
		uri    => 'http://ws.textanywhere.net/TA_WS',
	};

SendSMS($soapCfg,{
		'Client_ID'    => '*********',     # (str) Provided by TextAnywhere
		'Client_Pass'  => '*********',     # (str) Provided by TextAnywhere
		'Client_Ref'   => 'Client_Ref',    # (str) Send a Client reference of your choice that you will use with SMSstatus to get delivery reports
		'Billing_Ref'  => 'Billing_Ref',   # (str) Send a billing reference of your choice for future reference.
		'Connection'   => 2,               # (int) 1- Simulator(No SMS is sent). 2-Enterprise SMS. 3-Premium SMS
		'Originator'   => 'Piglet',        # (str) Formated number with a + e.g. +4478945612 or 11 charaters
		'OType'        => 1,               # (int) 0- the originator mus be a phone number. 1-the orginator can be 11 characters e.g "hello"
		'Destination'  => '+447738930000', # (str) Formated number with a + e.g. +4478945612
		'Body'         => 'message',       # (str) Text of you message
		'SMS_Type'     => 0,               # (int) 0- Normal SMS 1-Auto Open SMS, the message is displayed directly on the screen
		'SMS_encoding' => 0,               # (int) not in use at the moment. Must be set to 0
	});

exit;


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


sub ExecuteSOAP {
	my ($soapCfg,$msgParams) = @_;
	($soapCfg->{method} = (caller(1))[3]) =~ s/.*:://;

	DUMP($soapCfg);
	DUMP($msgParams);

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

	TRACE($resp->faultstring) if $resp->fault;
	return $resp;
}


sub TRACE {
	return unless $DEBUG;
	warn(shift());
}

sub DUMP {
	return unless $DEBUG;
	eval {
		require Data::Dumper;
		local $Data::Dumper::Indent = 2;
		local $Data::Dumper::Terse = 1;
		warn(shift().': '.Data::Dumper::Dumper(shift()));
	}
}


__END__


