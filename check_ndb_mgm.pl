#!/usr/bin/perl -w

use 5.6.1;
use strict;
use warnings;
use Data::Dumper;

use constant NDB_MGM_CMD => '/home/nagios/libexec/ndb_mgm --ndb-connectstring=mgmt1.network.com -e show';

my $rtn = 3;
my $msg = '';

my $status = parse_ndb_mgm_cmd(NDB_MGM_CMD);

if (!defined $status->{started}->{ndbd} || $status->{started}->{ndbd} < $status->{ndbd_nodes}) {
        $msg = "CRITICAL - Only $status->{started}->{ndbd} active ndbd nodes when expected $status->{ndbd_nodes}";
        $rtn = 2;

} elsif (!defined $status->{started}->{ndb_mgmd}) {
        $msg = "CRITICAL - No active ndb_mgmd nodes when expected at least 1";
        $rtn = 2;

} elsif (!defined $status->{started}->{mysqld} || $status->{started}->{mysqld} < 2) {
        $msg = "CRITICAL - Only $status->{started}->{mysqld} active mysqld nodes when expected at least 2";
        $rtn = 2;

} elsif (!$msg && 
        defined $status->{started}->{ndbd} && $status->{started}->{ndbd} == $status->{ndbd_nodes} &&
        $status->{started}->{ndbd} >= 2 &&
        defined $status->{started}->{mysqld} && $status->{started}->{mysqld} <= $status->{mysqld_nodes} &&
        $status->{mysqld_nodes} > 1 &&
        defined $status->{started}->{ndb_mgmd} && $status->{started}->{ndb_mgmd} == $status->{ndb_mgmd_nodes} &&
        $status->{ndb_mgmd_nodes} >= 1) {

        $rtn = 0;
        $msg = "OK - $status->{started}->{ndbd} ndbd, $status->{started}->{mysqld} mysqld, $status->{started}->{ndb_mgmd} ndb_mgmd";
}

#print Dumper($status);

chomp $msg;
$msg ||= 'UNKNOWN';
print "$msg\n";
exit $rtn;



sub parse_ndb_mgm_cmd {
        my $cmd = shift;
        my $block = '';
        my %status;

        if (open(PH,'-|',$cmd)) {
                while (local $_ = <PH>) {
                        chomp;
                        next if /^\s*$/;

                        if (/^Connected to Management Server at:\s+(\S+)/i) {
                                $status{server} = $1;

                        } elsif (/^(Cluster Configuration\s*|---*)$/i) {
                                # comment

                        } elsif (/^\[(\S+)\((\S+)\)\]\s+(\d+)\s+node\(s\)\s*$/i) {
                                $block = lc($1);
                                $status{"${block}_nodes"} = $3;

                        } elsif (/^id=(\d+)\s+(.*?)\s*$/) {
                                $status{nodes}->[$1] = { data => $2, type => $block };
                                my $node = $status{nodes}->[$1];
                                if ($node->{data} =~ /^\@(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+(.*?)\s*$/i) {
                                        $node->{ip} = $1;
                                        $node->{data} = $2;
                                }

                                if (/Version:?\s+([\d\.]+)/i) { $node->{version} = $1; }
                                if (/Nodegroup:?\s+(\d+)/i) { $node->{nodegroup} = $1; }
                                if (/\bMaster\)/i) { $node->{master} = 1; }
                                if (/\bnot\s+connected\b/) { $node->{not_connected} = 1; }
                                if (/\bnot\s+started\b/) { $node->{not_started} = 1; }
                                if (/\s+starting\b/) { $node->{starting} = 1; }

                                if (/accepting connect from (.+?)\s*\)/i) {
                                        my $host = $1;
                                        if ($host !~ /any\s+host/i) {
                                                $node->{accept_from} = $host;
                                        } else {
                                                $node->{accept_from} = '*';
                                        }
                                }

                                unless ($node->{starting} || $node->{not_connected} || $node->{not_started}) {
                                        $status{started}->{$block}++;
                                }

                        } else {
                                        # should never get to here
                                $rtn = 3;
                                $msg = "UNKNOWN - Unexpected string: $_\n";
                        }
                }
                close(PH);
        } else {
                $rtn = 3;
                $msg = "UNKNOWN - Failed to execute '$cmd': $!";
        }

        return \%status;
}


__END__
Connected to Management Server at: mgmt1.network.com:1186
Cluster Configuration
---------------------
[ndbd(NDB)]     4 node(s)
id=2    @10.10.10.65  (Version: 5.0.27, Nodegroup: 0)
id=3    @10.10.10.63  (Version: 5.0.27, Nodegroup: 0, Master)
id=4    @10.10.10.65  (Version: 5.0.27, Nodegroup: 1)
id=5    @10.10.10.63  (Version: 5.0.27, Nodegroup: 1)

[ndb_mgmd(MGM)] 1 node(s)
id=1    @10.10.10.18  (Version: 5.0.27)

[mysqld(API)]   10 node(s)
id=10   @10.10.10.65  (Version: 5.0.27)
id=11   @10.10.10.63  (Version: 5.0.27)
id=12 (not connected, accepting connect from monitoring.network.com)
id=13 (not connected, accepting connect from any host)
id=14 (not connected, accepting connect from any host)
id=15 (not connected, accepting connect from any host)
id=16 (not connected, accepting connect from any host)
id=17 (not connected, accepting connect from any host)
id=18 (not connected, accepting connect from any host)
id=19 (not connected, accepting connect from any host)
