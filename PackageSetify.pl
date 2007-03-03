#!/usr/bin/perl -w
# vim:ts=4:sw=4:tw=78

# Nicola Worthington <nicolaw@cpan.org>

use strict;
use File::Path ();
use File::Copy ();
use Getopt::Std ();
use lib qw(./);

use vars qw($VERSION);
$VERSION = sprintf('%d.%02d', q$Revision$ =~ /(\d+)/g);

# Get options
my $opt = {};
Getopt::Std::getopt('v:a:o:p:h', $opt);
help() if exists $opt->{h};

# Package name
my $PKG = shift(@ARGV) || '';
(my $PKG_DIR = $PKG) =~ s/::/\//g;
help() unless $PKG =~ /^[0-9a-z\_\:]+$/i;
die "Cannot find $PKG_DIR.pm\n" unless -f "$PKG_DIR.pm";

# Package version
my $PKG_VERSION = $ARGV[1] || '';
eval "use $PKG";
unless ($@) {
	$PKG_VERSION = eval("\$${PKG}::VERSION");
	print "$PKG is version $PKG_VERSION\n";
}
die "Couldn't determine valid module version. Use the -v option.\n"
	unless $PKG_VERSION && $PKG_VERSION =~ /^\S+$/;

# Host arch and OS version
# my $arch = exists $opt->{a} && $opt->{a} =~ /^\S+$/ ? $opt->{a} : `/bin/uname -m`; 
my $arch = exists $opt->{a} && $opt->{a} =~ /^\S+$/ ? $opt->{a} : 'default'; 
chomp $arch;
#my $osver = exists $opt->{o} && $opt->{o} =~ /^\S+$/ ? $opt->{o} : `/bin/uname -r`;
my $osver = exists $opt->{o} && $opt->{o} =~ /^\S+$/ ? $opt->{o} : 'default';
chomp $osver;
#my $perlver = exists $opt->{p} && $opt->{p} =~ /^\S+$/ ? $opt->{p} : $];
my $perlver = exists $opt->{p} && $opt->{p} =~ /^\d+\.\d+$/ ? $opt->{p} : 'default';
chomp $perlver;

# Make the tree
my $full_tree = "./PackageSet/$PKG_DIR/version-$PKG_VERSION/arch-$arch/osver-$osver/host-default/perl-$perlver";
unless (-d $full_tree) {
	eval { File::Path::mkpath($full_tree,1) };
	if ($@) {
		die "Couldn't create $full_tree: $@\n";
	}
}

make_packageset_stub($PKG,$PKG_VERSION,$full_tree);
copy_code_into_packageset($PKG,$PKG_VERSION,$full_tree);
exec("find ./PackageSet/$PKG_DIR/");

sub copy_code_into_packageset {
	my ($pkg,$ver,$full_tree) = @_;
	print "Copying files in to PackageSet directory ...\n";
	my @stubtree = split(/::/,$pkg);
	(my $stubtree = $pkg) =~ s/::/\//g;
	my $stubbasename = pop(@stubtree).'.pm';
	my $stubfile = join('/','./PackageSet',@stubtree,$stubbasename);
	my $cmd = "cp -r $stubtree $stubtree.pm $full_tree/";
	system($cmd);
	if (-f "auto/$stubtree.pm" || -d "auto/$stubtree/") {
		mkdir "$full_tree/auto";
		my $cmd2 = "cp -r auto/$stubtree auto/$stubtree.pm $full_tree/auto/";
		system($cmd2);
	}
}

sub make_packageset_stub {
	my ($pkg,$ver,$full_tree) = @_;
	my @stubtree = split(/::/,$pkg);
	my $stubbasename = pop(@stubtree).'.pm';
	my $stubfile = join('/','./PackageSet',@stubtree,$stubbasename);
	if (-f $stubfile) {
		die "PackageSet stub $stubfile already exists; aborting\n";
	}
	print "Writing PackageSet stub for $pkg: $stubfile\n";
	open(STUB,">$stubfile") || die "Unable to open filehandle STUB for file '$stubfile': $!\n";
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$mon++; $year += 1900;
	my $stubversion = sprintf('%04d%02d%02d',$year,$mon,$mday);
	(my $majorver = $ver) =~ s/\..+//g;
	print STUB <<EOT;
package PackageSet::$pkg;

require PackageSet::Core;
\@ISA="PackageSet::Core";

\$VERSION="$stubversion";

\$latest_version_of = {
        "" => "$majorver",
        "$majorver" => "$ver",
        "$ver" => "$ver",
    };

1;
EOT
	close(STUB) || die "Unable to close filehandle STUB for file '$stubfile': $!\n";
}

sub help {
	print <<EOT;
Syntax: $0 <package> [-v version] [-a arch] [-o osver] [-p perlver]
	-v version       Specify module version number
	-a arch          Specify machine architechure (eg sun4u-64)
	-o osver         Specify OS version (eg 5.8)
	-p perlver       Specify Perl version (eg 5.006001)

	This script should be executed from a vanilla install path of
	a perl module. For example, if you untar a CPAN-Module-0.99.tar.gz,
	and then install it in to a temporary location of ~/todo/modules,
	this script should be executed from that temporary location. It
	should then be able to find ./CPAN/Module.pm and create a
	PackageSet/CPAN/Module.pm and related subdirectories in that
	locations which can then be moved in to a live environment.

	This script is very rough and ready. Ask Nicola Worthington if
	you need assistance.
EOT
	exit;
}




