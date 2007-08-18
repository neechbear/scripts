#!/usr/bin/perl -w

# Nicola Worthington 2007
# vcf2text.pl backup.vcf | a2ps -l 98

use strict;
use warnings;
use Text::vCard::Addressbook qw();

my $file = $ARGV[0] || '';
die "Syntax: $0 <filename.vcf>\n" unless $file && -f $file;
my $address_book = Text::vCard::Addressbook->new({
		'source_file' => $file,
	});

my @phones = qw(cell home work fax other);
my $format = "%-27s %-13s %-13s %-13s %-13s %-13s\n";
printf($format, 'name',@phones);
printf($format, '=' x 27, ('=' x 13) x 5);

foreach my $vcard ($address_book->vcards()) {
	my $name = $vcard->FN || build_fullname($vcard);
	$name =~ s/[^[:print:]]/ /g;
	next unless defined $name && $name =~ /\S/;

	my %tel = map { $_ => '' } @phones;
	for my $node (@{$vcard->get('TEL')}) {
		my $ok = 0;
		for my $type (@phones) {
			if ($node->is_type($type)) {
				$tel{$type} = $node->value;
				$ok = 1;	
			}
		}
		$tel{other} = $node->value
			if !$ok && !$tel{other};
	}

	printf($format, $name, map { $tel{$_} } @phones);
}

exit;

sub build_fullname {
	my $vcard = shift;
	my @names;
	my @name_types = qw(prefixes given middle family suffixes);
	for my $node ($vcard->get({'node_type' => 'NAME'}, types => \@name_types)) {
		for my $method (@name_types) {
			eval {
				eval 'push @names, $node->'.$method.' if $node->'.$method.';';
			};
		}
	}
	return join(' ',@names);
}

__END__

