#!/usr/bin/perl -w

#%PASSWORDS = (
#        '*' => {
#                access => 'poo',
#                secure_enable => 'woo',
#        },
#        'paix.ca.us.ftech.net' => {
#        },
#                access => 'bar',
#                secure_enable => 'foo',
#);

use strict;
use English;
use Data::Dumper;
use IO::Socket;
use Net::Netmask;
use Net::Telnet::Cisco;
use vars qw(%ARP %PASSWORDS %MAP %THEME %ciscosw %portmap %passwords $nextid %nodes %edges @DOT);

require './passwords.pl';
require './findport-mactab.pl';
require './theme.pl';
require './map.pl' if -e './map.pl';

my @switches = @ARGV;
unless (@switches) {
	#die "Syntax: $PROGRAM_NAME [switch hostname] ...\n";
	@switches = split(/\s+|\n/,`switches|egrep -v "(switch-305-1|switch-rack-1|switch-2.tynant|cardiff|tynant)"`);
}

######################################################################

for my $switch (@switches) {
	%ciscosw = ();
	%portmap = ();
	%passwords = ();

	for (keys %PASSWORDS) {
	    next if $_ eq '*';
	    %passwords = %{$PASSWORDS{$_}} if $switch =~ /$_/;
	}
	%passwords = %{$PASSWORDS{'*'}} unless keys %passwords;

	process_switch($switch);

	foreach my $port (sort keys %portmap) {
	    my @mactab = @{$portmap{$port}};
	    foreach my $mac (@mactab) {
		my $host = resolve($ARP{$mac});

		$host = 'rtr-core-x.ensign.ftech.net' if $host && "$host" eq 'core-a.ensign.ftech.net';
		$host = 'rtr-core-x.ensign.ftech.net' if $host && "$host" eq 'rtr-core-1i.ensign.ftech.net';

		add_map_record($switch, $port, $mac, $ARP{$mac}, $host);
	    }
	}

	foreach my $port (sort keys %ciscosw) {
	    my $ip = process_port($switch, $port);
	    add_map_record($switch, $port, '', $ip, resolve($ip));
	}
}

$nextid = 1;
@DOT = ("digraph G {");
for my $switch (keys %MAP) {
	my @equipment = @{$MAP{$switch}};
	foreach my $equip (@equipment) {
		my $equip_desc = $equip->{host} || $equip->{ip} || $equip->{mac} || $equip->{port};

		my ($switch_ref,$switch_new) = id($switch);
		my ($equip_ref,$equip_new) = id($equip_desc);

#		if ($equip_desc =~ /^switch-/) {
#			unless (exists $edges{"${switch_ref}-${equip_ref}"} && exists $edges{"${equip_ref}-${switch_ref}"}) {
#				push @DOT,sprintf("\t%s -> %s;",$switch_ref,$equip_ref);
#				$edges{"${switch_ref}-${equip_ref}"} = 1;
#			}
#		} else {
			unless (exists $edges{"${switch_ref}-${equip_ref}"} || exists $edges{"${equip_ref}-${switch_ref}"}) {
				push @DOT,sprintf("\t%s -> %s [style=\"bold\",arrowhead=\"none\",arrowtail=\"none\"];",$switch_ref,$equip_ref);
				$edges{"${switch_ref}-${equip_ref}"} = 1;
			}
#		}

		describe_node($equip_ref,$equip_desc) if $equip_new;
		describe_node($switch_ref,$switch) if $switch_new;
	}
}
push @DOT,"}";

open(FH,">$$.dot") || die "Unable to open file handle FH for file '$$.dot': $!\n";
print FH "$_\n" for @DOT;
close(FH) || die "Unable to close file handle FH for file '$$.dot': $!\n";

for my $fmt (qw/png jpg gif/) {
	my $cmd = "dot -T$fmt $$.dot -o ~/public_html/output.$fmt";
	print "$cmd\n";
	system($cmd);
}

exit;

######################################################################

# Find out what mac addresses are connected to this switch
sub handle_mactab {
    chomp(my @output = @_);

    for (@output) {
	my ($mac,$type,$vlan,$port) = ('','','','');
	if (/^\s*([a-z0-9]{4}\.[a-z0-9]{4}\.[a-z0-9]{4})\s+(\S+)\s+(\d*)\s+([a-zA-Z0-9]+\/\d+)\s*$/) {
	    ($mac,$type,$vlan,$port) = ($1,$2,$3,$4); # Ensign

	} elsif (/^\s*(\d*)\s+([a-z0-9]{4}\.[a-z0-9]{4}\.[a-z0-9]{4})\s+(\S+)\s+([a-zA-Z0-9]+\/\d+)\s*$/) {
	    ($vlan,$mac,$type,$port) = ($1,$2,$3,$4); # PAIX
	}
	$port =~ s/Fas?(\d)/FastEthernet$1/;;
	if (!$ciscosw{$port} && $mac) {
	    my @tmp;
            @tmp = @{$portmap{$port}} if exists $portmap{$port};
	    push @tmp, $mac;
	    $portmap{$port} = [@tmp];
	}
    }
}

sub process_switch {
    my $host = shift;

    print "Connecting to $host ...\n";
    my $cs = Net::Telnet::Cisco->new(Host => $host, Port => 23);
    $cs->login('', $passwords{access});
    $cs->errmode(sub {;});
    my @output1 = $cs->cmd('terminal length 0');

    chomp(my @output2 = $cs->cmd('show cdp neighbor'));
    if (scalar @output2) {
	handle_cdp(@output2);
    } else {
	warn sprintf("Error: %s\n", $cs->errmsg());
    }
    
    unless ($cs->enable($passwords{secure_enable})) {
	warn sprintf("Enable error: %s\n", $cs->errmsg());
    } else {
	chomp(my @output3 = $cs->cmd('show mac-address-table'));
	if (scalar @output3) {
	    handle_mactab(@output3);
	} else {
	    warn sprintf("Error: %s\n", $cs->errmsg());
	}
    }

    $cs->cmd('logout');
}

sub process_port {
    my ($host,$port) = @_;

    my $cs = Net::Telnet::Cisco->new( Host => $host, Port=>23 );
    $cs->login('', $passwords{access});
    $cs->errmode( sub { ; } );
    my @data = $cs->cmd("sh cdp nei ". $port . " detail");

    while (my $line = shift @data ) {
	if ( $line =~ /IP address: ([0-9.]*)/ ) {
	    $cs->cmd("logout");
	    return $1;
	}
    }

    $cs->cmd("logout");
    return "unknown";
}

# Find out what cisco switches are connected
sub handle_cdp {
    chomp(my @output = @_);

    my $ok;
    for (@output) {
	if ($ok) {
	    if (my ($host,$port) = m#^([^F ]*) *(Fas [01]/[0-9]+)#) {
	    	$port =~ s/Fas /FastEthernet/;
	    	$port =~ s/\s+//g;

		$host = 'switch-305-1.ensign.ftech.net' if $host eq 'ensw800C01D811DE1';
	    	$host =~ s/\s+//g;
		$host =~ s/^swt-/switch-/;
		$host =~ s/\.(en|ensign).*$/.ensign.ftech.net/;
		$host =~ s/\.(th|tele).*$/.telehouse.ftech.net/;
                $ciscosw{$port} = $host;
            } else {
		warn "Unable to process cdp record data '$_'\n";
	    }
	}
	$ok = 1 if /Local Int/;
    }
}

# Resolve a hostname to an IP
sub resolve {
	my $str = shift;
	return $str if !$str || $str =~ /^(\s*|0)$/;
	unless (isip($str)) { # Resolve hostname to IP
	        my @addr = unpack('C4', (gethostbyname($str))[4] || '');
	        my $ip = '';
	        $ip = sprintf("%d.%d.%d.%d", @addr) if @addr;
	        return $ip if isip($ip);
	} else { # Resolve IP to hostname
	        my $iaddr = (gethostbyname($str))[4] || '';
	        my $ip = sprintf("%d.%d.%d.%d", unpack('C4', $iaddr));
	        my $host = (gethostbyaddr($iaddr, AF_INET))[0] || '';
		return $host unless isip($host);
	}
	return $str;
}

# Is this IP or netblock inside of Frontier's ranges?
sub isftech {
        my $str = shift || '';
        return 0 unless $str;
        my @ftech_netblocks = ('195.200.0.0/19','212.32.0.0/17');
        foreach my $ftech_netblock (@ftech_netblocks) {
                my $blockobj = new Net::Netmask($ftech_netblock);
                return 1 if $blockobj->match($str);
        }
        return 0;
}

# Is this string a netblock?
sub isnetblock {
        my $str = shift || '';
        return 1 if isip($str) || iscidr($str);
        return 0;
}

# Is this string a CIDR style prefix?
sub iscidr {
        my $str = shift || '';
        if (my ($ip,$prefix) = $str =~ /^(.+?)\/(\d+)$/) {
                return 1 if isip($ip) && $prefix =~ /^[0-32]$/;
        }
        return 0;
}

# Is this string an IP address?
sub isip {
        my $str = shift || '';
        $str = 0 unless $str =~ /
                ([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-9]|2[0-4][0-9]|25[0-5])\.
                ([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-9]|2[0-4][0-9]|25[0-5])\.
                ([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-9]|2[0-4][0-9]|25[0-5])\.
                ([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-9]|2[0-4][0-9]|25[0-5])
                        /x;
        return $str;
}

sub describe_node {
	my ($noderef,$str) = @_;

	(my $shorthost = $str) =~ s/\.ftech\.net$//i;
	(my $shorthost2 = $shorthost) =~ s/\./\\n\./;

	my $nodegroup = '*';
	if (exists $THEME{$str}) {
		$nodegroup = $str;
	} elsif (my @x = $str =~ /^([a-z0-9]+)-(?:([a-z0-9]+)-)?/) {
      		$nodegroup = $x[0] if exists $THEME{$x[0]};
		$nodegroup = join('-',@x) if $x[1] && exists $THEME{join('-',@x)};
	}
	my $fmt = "\t%s [";
	my @fmt;
	while (my ($k,$v) = each %{$THEME{$nodegroup}}) {
		push @fmt,"$k=\"$v\"";
	}
	push @fmt, "label=\"%s\"" unless exists $THEME{$nodegroup}->{label};
	$fmt .= join(',',@fmt)."]";

	push @DOT,sprintf($fmt,$noderef,$shorthost2);
}

# Get node id or create a new one
sub id {
	my $str = shift;
	if (exists $nodes{$str}) {
		return ($nodes{$str},0);
	} else {
		$nodes{$str} = $nextid;
		my $noderef = $nextid;
		$nextid++;
		return ($nodes{$str},1);
	}
}

# Add record to our data map
sub add_map_record {
	my ($switch,$port,$mac,$ip,$host) = @_;
	my @tmp;
	@tmp = @{$MAP{$switch}} if exists $MAP{$switch};
	my %tmp = (
		host	=> $host,
		ip	=> $ip,
		mac	=> $mac,
		port	=> $port,
	);
	push @tmp,{%tmp};
	$MAP{$switch} = [@tmp];
}





