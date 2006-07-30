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



