#!/home/nicolaw/webroot/perl/bin/perl -w

use strict;
use File::Basename;
use DBI;
use File::Slurp;
use Data::Dumper;
use HTML::Entities;

my $dbh = DBI->connect('DBI:mysql:dvds:localhost','nicolaw',undef);
my %names_processed;
my %keywords_processed;

my @files = glob('*/tt???????');
for my $file (@files) {
	my $str = read_file($file);
	my $ref = {}; my $VAR1;
	$ref = eval $str;

	my $sql = 'SELECT id FROM title WHERE id = ?';
	my $sth = $dbh->prepare($sql);
	$sth->execute($ref->{imdbid});

	my ($id) = $sth->fetchrow_array();
	if (defined $id && $id eq $ref->{imdbid}) {
		print "Skipping $id - $ref->{title} ...\n";
	}

	for (keys %{$ref}) {
 		if (defined $ref->{$_} && !ref($ref->{$_})) {
			$ref->{$_} = decode_entities($ref->{$_})
		}
	}
	for my $key (qw(writers producers directors cast keywords)) {
		for (keys %{$ref->{$key}}) {
			if (defined $ref->{$key}->{$_} && !ref($ref->{$key}->{$_})) {
				$ref->{$key}->{$_} = decode_entities($ref->{$key}->{$_});
			}
		}
	}

	update_title($ref,$dbh);

	update_people($ref,$dbh,'directors');
	update_people($ref,$dbh,'producers');
	update_people($ref,$dbh,'writers');
	update_people($ref,$dbh,'cast');

	update_flag($ref,$dbh);
	update_keyword($ref,$dbh);
	update_genre($ref,$dbh);
}

exit;

sub update_genre {
	my ($ref,$dbh) = @_;

	for (@{$ref->{genres}}) {
		my $sql = 'INSERT INTO genre (title_id,genre) VALUES (?,?)';
		my $sth = $dbh->prepare($sql);
		$sth->execute($ref->{imdbid},$_);
	}
}

sub update_flag {
	my ($ref,$dbh) = @_;

	for (@{$ref->{flags}}) {
		next unless defined $_;
		my $sql = 'INSERT INTO flag2title (flag_id,title_id) VALUES (?,?)';
		my $sth = $dbh->prepare($sql);
		$sth->execute($_,$ref->{imdbid});
	}
}

sub update_keyword {
	my ($ref,$dbh) = @_;

	while (my ($keyword,$long) = each %{$ref->{keywords}}) {
		if (!exists $keywords_processed{$keyword}) {
			my $sql = 'INSERT INTO keyword (id,keyword) VALUES (?,?)';
			my $sth = $dbh->prepare($sql);
			$sth->execute($keyword,$long);
			$keywords_processed{$keyword} = 1;
		}
		my $sql = 'INSERT INTO keyword2title (keyword_id,title_id) VALUES (?,?)';
		my $sth = $dbh->prepare($sql);
		$sth->execute($keyword,$ref->{imdbid});
	}
}

sub update_people {
	my ($ref,$dbh,$people) = @_;

	(my $table_name = $people) =~ s/s$//;
	while (my ($id,$name) = each %{$ref->{$people}}) {
		update_name($dbh,$id,$name);
		my $sql = "INSERT INTO $table_name (name_id, title_id) VALUES (?,?)";
		my $sth = $dbh->prepare($sql);
		$sth->execute($id, $ref->{imdbid});
	}
}

sub update_name {
	my ($dbh,$id,$name) = @_;

	return if exists $names_processed{$id};
	my $sql = 'INSERT INTO name (id, name) VALUES (?,?)';
	my $sth = $dbh->prepare($sql);
	$sth->execute($id,$name);
	$names_processed{$id} = 1;
}

sub update_title {
	my ($ref,$dbh) = @_;

	$ref->{title} =~ s/^['"](.+?)["']$/$1/;
	print "Importing $ref->{imdbid} - $ref->{title} ...\n";

	my $sql = 'INSERT INTO title (id,title,year,certification,tagline,image) VALUES (?,?,?,?,?,?)';
	my $sth = $dbh->prepare($sql);

	$sth->execute(
			$ref->{imdbid},
			$ref->{title},
			$ref->{year},
			$ref->{certification},
			$ref->{tagline},
			$ref->{image},
		);
}

__DATA__

create table title (
	id CHAR(9) NOT NULL PRIMARY KEY,
	title VARCHAR(64) NOT NULL,
	year YEAR,
	certification VARCHAR(5),
	tagline VARCHAR(255),
	image VARCHAR(64)
) TYPE=InnoDB;

create table writer (
	title_id CHAR(9) NOT NULL,
	name_id CHAR(9) NOT NULL
) TYPE=InnoDB;

create table cast (
	title_id CHAR(9) NOT NULL,
	name_id CHAR(9) NOT NULL
) TYPE=InnoDB;

create table director (
	title_id CHAR(9) NOT NULL,
	name_id CHAR(9) NOT NULL
) TYPE=InnoDB;

create table producer (
	title_id CHAR(9) NOT NULL,
	name_id CHAR(9) NOT NULL
) TYPE=InnoDB;

create table keyword2title (
	keyword_id VARCHAR(128) NOT NULL,
	title_id CHAR(9) NOT NULL,
	PRIMARY KEY (keyword_id, title_id)
) TYPE=InnoDB;

create table keyword (
	id VARCHAR(128) NOT NULL UNIQUE,
	keyword VARCHAR(255) NOT NULL
) TYPE=InnoDB;

create table name (
	id CHAR(9) NOT NULL PRIMARY KEY,
	name VARCHAR(32) NOT NULL
) TYPE=InnoDB;

create table genre (
	title_id CHAR(9) NOT NULL,
	genre VARCHAR(32) NOT NULL,
	PRIMARY KEY (title_id, genre)
) TYPE=InnoDB;

create table flag (
	id VARCHAR(5) NOT NULL PRIMARY KEY,
	description VARCHAR(64)
) TYPE=InnoDB;

create table flag2title (
	flag_id VARCHAR(5) NOT NULL,
	title_id CHAR(9) NOT NULL,
	PRIMARY KEY (flag_id, title_id)
) TYPE=InnoDB;


