package Foo;

use 5.6.1;
use strict;
use Scalar::Util qw(refaddr);

our $VERSION = sprintf('%d.%02d', q$Revision$ =~ /(\d+)/g);
our $DEBUG ||= $ENV{DEBUG} ? 1 : 0;

my $objstore = {};

sub new {
	ref(my $class = shift) && croak 'Class name required';
	croak 'Odd number of elements passed when even was expected' if @_ % 2;

	my $self = bless \(my $dummy), $class;
	$objstore->{refaddr($self)} = {@_};
	my $stor = $objstore->{refaddr($self)};

	return $self;
}


sub test {
	my ($self,$stor,$opts) = _require(\@_,
									require => [qw(domain)],
									#valid => [qw(domain filename)]
								);

	use Data::Dumper;
	print Dumper($opts);
}



sub _require {
	my $self = shift(@{$_[0]});
	local $Carp::CarpLevel = 2;
	croak 'Not called as a method' if !ref($self) || !UNIVERSAL::isa($self,__PACKAGE__);

	my $stor = $objstore->{refaddr($self)};
	return ($self,$stor,$_[0]) unless @_ > 1;

	my %param;
	for (my $i = 1; $i < @_; $i += 2) {
		if (grep($_ eq $_[$i],qw(require valid)) && ref($_[$i+1]) eq 'ARRAY') {
			$param{$_[$i]} = $_[$i+1];
		} else {
			local $Carp::CarpLevel = 1;
			confess(sprintf(
				"Illegal key '%s' or value ref type '%s' passed to _require()",
				$_[$i], ref($_[$i+1])
			));
		}
	}

	my $opts = {};
	croak 'Odd number of elements passed when even was expected' if @{$_[0]} % 2;
	for (my $i = 0; $i < @{$_[0]}; $i += 2) {
		$opts->{$_[0]->[$i]} = $_[0]->[$i+1] if
				defined $param{valid} ?
				grep($_[0]->[$i] eq $_,(@{$param{valid}},@{$param{require}})) : 1
	}

	for my $key (@{$param{require}}) {
		croak "Required parameter '$key' missing when expected"
			unless exists $opts->{$key};
	}

	return ($self,$stor,$opts);
}


