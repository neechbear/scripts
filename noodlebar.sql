DROP TABLE IF EXISTS nb_item;
CREATE TABLE nb_item (
	item_id SMALLINT UNSIGNED NOT NULL PRIMARY KEY,
	type ENUM('noodles','soup','rice','wokrice','side','sauce','extra') NOT NULL,
	style_id SMALLINT UNSIGNED,
	title VARCHAR(48) NOT NULL,
	info VARCHAR(128),
	qty TINYINT UNSIGNED,
	children BOOL,
	vegetarian BOOL,
	nuts BOOL,
	price DECIMAL(5,2)
);

DROP TABLE IF EXISTS nb_style;
CREATE TABLE nb_style (
	style_id SMALLINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	style VARCHAR(32) NOT NULL,
	description VARCHAR(128) NOT NULL
);

DROP TABLE IF EXISTS nb_option;
CREATE TABLE nb_option (
	type ENUM('noodles','soup','rice') NOT NULL,
	variant VARCHAR(12) NOT NULL,
	description VARCHAR(128) NOT NULL,
	suppliment DECIMAL(5,2),
	PRIMARY KEY (type,variant)
);

INSERT INTO nb_style VALUES
	(1,'wok fried noodles','w onion, beansprout, carrot & spring onion, lightly seasoned w soy sauce'),
	(2,'soup noodles','traditional clear, lightly seasoned chinese noodle soup, garnished w chinese leaf & spring onion'),
	(3,'stir fry','light soy flavoured sauce w onion'),
	(4,'sweet and sour','w onion, pineapple & peppers'),
	(5,'blackbean','blackbean sauce w mild chili, onion & peppers'),
	(6,'chinese curry','mild sauce w wok fried onion'),
	(7,'yellowbean','sweet hoi sin & crushed ywlloebean sauce w onion, cashew & peppers'),
	(8,'chili & garlic','spicy sauce w fresh chili, garlic, onion & peppers'),
	(9,'kung po','sweet & tancy sauce made w orange, mild chili, pineapple, cashew & peppers'),
	(10,'chinese roast gravy','w chinese leaf. spring onion garnish & gravy'),
	(11,'cantonese','tangy, sweet sauce w tomato, onion & peppers'),
	(12,'ginger & pring onion','w soy sauce, carror, sliced ginger & onion'),
	(13,'malay curry','medium coconut curry w potato, baby corn & peas'),
	(14,'wok fried rice','egg rice w sesame oil, soy sauce & garden peas');

INSERT INTO nb_option VALUES
	('noodles','yo min','medium chinese egg and wheat noodles',NULL),
	('noodles','udon','thick japenese wheat flour noodles',NULL),
	('noodles','ho fun','think, flat chinese rice flour noodles',NULL),
	('noodles','mai fun','fine vermicelli rice flour noodles',NULL),

	('soup','mai fun','fine vermicelli rice flour noodles',NULL),
	('soup','udon','thick japenese wheat flour noodles',NULL),
	('soup','ho fun','think, flat chinese rice flour noodles',NULL),

	('rice','steamed','steamed rice',NULL),
	('rice','egg-fried','egg-fried rice',NULL),

	('rice','yo min','medium chinese egg and wheat noodles',0.60),
	('rice','udon','thick japenese wheat flour noodles',0.60),
	('rice','ho fun','think, flat chinese rice flour noodles',0.60),
	('rice','mai fun','fine vermicelli rice flour noodles',0.60);

INSERT INTO nb_item VALUES
	(1,'side',NULL,'small prawn crackers','good for 1 or 2',NULL,NULL,NULL,NULL,0.80),
	(2,'side',NULL,'large prawn crackers','for 2 or more',NULL,NULL,NULL,NULL,1.20),
	(3,'side',NULL,'vegetarian spring rolls','w sweet chili dip',6,NULL,1,NULL,2.20),
	(4,'side',NULL,'crispy \'seaweed\'','w dried shrimp seasoning',NULL,NULL,NULL,NULL,2.20),
	(5,'side',NULL,'crispy coated chicken wings',NULL,NULL,NULL,NULL,NULL,3.30),
	(6,'side',NULL,'tempura battered vegetables','w sweet chili dip (green bean, carrots, cauliflower & peppers)',NULL,NULL,1,NULL,3.30),
	(7,'side',NULL,'wok fried mixed vegetables & cashews','(onion, spring onion, chinese leaf, b/sprout, m/room, babycorn, carrot, cashew, peas, peppers & garlic)',NULL,NULL,1,1,3.30),
	(8,'side',NULL,'tempura battered king prawns',NULL,4,NULL,NULL,NULL,3.30),
	(9,'side',NULL,'sesame prawn toast',NULL,NULL,NULL,NULL,NULL,3.30),
	(10,'side',NULL,'deep fried ribs','w bbq dip',NULL,NULL,NULL,NULL,3.30),
	(11,'side',NULL,'chicken satay skewers','w spicy peanut sauce',5,NULL,NULL,1,3.60),
	(12,'side',NULL,'seared vegetable dumplings','w spiced soy dip',4,NULL,1,NULL,3.60),
	(13,'side',NULL,'seared meat dumplings','w spiced soy dip',4,NULL,NULL,NULL,3.60),
	(14,'side',NULL,'salt & pepper ribs','w chili & garlic',NULL,NULL,NULL,NULL,3.60),
	(15,'side',NULL,'tom yum prawns','in coriander & lemongrass batter w sweet chili dip',NULL,NULL,NULL,NULL,3.60),
	(16,'side',NULL,'bak choi','w vegetarian \'oyster\' sauce',NULL,NULL,1,NULL,3.60),
	(17,'side',NULL,'salt & pepper squid','w chili & garlic',NULL,NULL,NULL,NULL,3.80),
	(18,'side',NULL,'sticky cantonese ribs','in a sweet rich tomato sauce',NULL,NULL,NULL,NULL,3.80),
	(19,'side',NULL,'thai fish skewers','boneless cod fillet',4,NULL,NULL,NULL,3.80),
	(20,'side',NULL,'duck spring rolls','w hoi sin dip',2,NULL,NULL,NULL,3.80);

INSERT INTO nb_item VALUES
	(30,'noodles',1,'chicken',NULL,NULL,1,NULL,NULL,4.90),
	(31,'noodles',1,'beef',NULL,NULL,NULL,NULL,NULL,4.90),
	(32,'noodles',1,'roast \'cha  sui\' pork',NULL,NULL,NULL,NULL,NULL,5.10),
	(33,'noodles',1,'roast duck',NULL,NULL,NULL,NULL,NULL,5.10),
	(34,'noodles',1,'mixed roast ruck & pork',NULL,NULL,NULL,NULL,NULL,5.10),
	(35,'noodles',1,'mixed vegetable & cashew','additional chinese leaf, peas, babycorn, m/room, cashew & peppers',NULL,NULL,1,1,4.90),
	(36,'noodles',1,'mixed meat','w beef balls, chicken, pork & roast duck',NULL,NULL,NULL,NULL,5.20),
	(37,'noodles',1,'king prawn',NULL,NULL,NULL,NULL,NULL,5.40),
	(38,'noodles',1,'seafood','w prawn, mussel, squid, \'crab\' & peppers',NULL,NULL,NULL,NULL,5.50),
	(39,'noodles',1,'singapore','spicy w chicken, pork, shrimp & peppers',NULL,NULL,NULL,NULL,5.40),
	(40,'noodles',1,'vegetarian singapore','spicy version of our mixed vegetable and cashew',NULL,NULL,1,1,5.20);

INSERT INTO nb_item VALUES
	(41,'soup',2,'chicken',NULL,NULL,NULL,NULL,NULL,4.90),
	(42,'soup',2,'beef',NULL,NULL,NULL,NULL,NULL,4.90),
	(43,'soup',2,'roast \'cha sui\' pork',NULL,NULL,NULL,NULL,NULL,5.10),
	(44,'soup',2,'roast duck',NULL,NULL,NULL,NULL,NULL,5.10),
	(45,'soup',2,'mixed roast duck & pork',NULL,NULL,NULL,NULL,NULL,5.10),
	(46,'soup',2,'mixed vegetable','onion, spring onion, chinese leaf, b/sprout, peas, baby corn, carrot, cashew, m/room & peppers',NULL,NULL,1,1,4.90),
	(47,'soup',2,'seafood','w prawns, mussels, squid, \'crab\' sticks, fishballs',NULL,NULL,NULL,NULL,5.50),
	(48,'soup',2,'wonton','freshly made traditional pork & prawn raviloi',NULL,NULL,NULL,NULL,5.50);

INSERT INTO nb_item VALUES
	(50,'rice',3,'chicken & mushroom',NULL,NULL,1,NULL,NULL,4.90),
	(51,'rice',3,'beef & mushroom',NULL,NULL,NULL,NULL,NULL,4.90),
	(52,'rice',3,'chicken & pineapple',NULL,NULL,NULL,NULL,NULL,4.90),
	(53,'rice',3,'king prawn & pineapple',NULL,NULL,1,NULL,NULL,5.30),
	(54,'rice',3,'mixed meat & vegetable','w pork, prawn, beef, chicken & duck',NULL,NULL,NULL,NULL,5.30),

	(60,'rice',4,'chicken balls in batter',NULL,NULL,1,NULL,NULL,4.90),
	(61,'rice',4,'hong kong style crispy coated chicken',NULL,NULL,1,NULL,NULL,5.00),
	(62,'rice',4,'hong kong style crispy coated king prawn',NULL,NULL,NULL,NULL,NULL,5.30),
	(63,'rice',4,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,4.90),

	(70,'rice',5,'chicken',NULL,NULL,NULL,NULL,NULL,5.00),
	(71,'rice',5,'beef',NULL,NULL,NULL,NULL,NULL,5.00),
	(72,'rice',5,'roast duck',NULL,NULL,NULL,NULL,NULL,5.30),
	(73,'rice',5,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,4.90),
	(74,'rice',5,'king prawn',NULL,NULL,NULL,NULL,NULL,5.40),
	(75,'rice',5,'seafood','w prawn, mussel, squid, \'crab\' sticks & fishballs',NULL,NULL,NULL,NULL,5.50),

	(80,'rice',6,'chicken',NULL,NULL,NULL,NULL,NULL,4.90),
	(81,'rice',6,'beef',NULL,NULL,NULL,NULL,NULL,4.90),
	(82,'rice',6,'king prawn',NULL,NULL,NULL,NULL,NULL,5.30),
	(83,'rice',6,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,4.90),
	(84,'rice',6,'noodlebar special','w chicken, beef, king prawn, duck and cha sui pork',NULL,NULL,NULL,NULL,5.40),

	(90,'rice',7,'chicken',NULL,NULL,NULL,NULL,1,5.00),
	(91,'rice',7,'beef',NULL,NULL,NULL,NULL,1,5.00),
	(92,'rice',7,'king prawn',NULL,NULL,NULL,NULL,1,5.40),
	(93,'rice',7,'mixed vegetable',NULL,NULL,NULL,1,1,4.90),

	(100,'rice',8,'chicken',NULL,NULL,NULL,NULL,NULL,5.00),
	(101,'rice',8,'king prawn',NULL,NULL,NULL,NULL,NULL,5.40),
	(102,'rice',8,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,4.90),

	(110,'rice',9,'sticky coated chicken',NULL,NULL,NULL,NULL,1,5.20),
	(111,'rice',9,'sticky coated king prawn',NULL,NULL,NULL,NULL,1,5.60),
	(112,'rice',9,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,5.10),
	(113,'rice',9,'sticky \'chili\' beef strips','w carrot only',NULL,NULL,NULL,1,5.20),

	(120,'rice',10,'roast cha sui pork',NULL,NULL,NULL,NULL,NULL,5.20),
	(121,'rice',10,'roast duck',NULL,NULL,NULL,NULL,NULL,5.20),
	(122,'rice',10,'mixed roast duck & cha sui pork',NULL,NULL,NULL,NULL,NULL,5.20),

	(130,'rice',11,'chicken',NULL,NULL,NULL,NULL,NULL,5.00),
	(131,'rice',11,'beef',NULL,NULL,NULL,NULL,NULL,5.00),
	(132,'rice',11,'king prawn',NULL,NULL,NULL,NULL,NULL,5.40),

	(140,'rice',12,'chicken',NULL,NULL,NULL,NULL,NULL,5.00),
	(141,'rice',12,'beef',NULL,NULL,NULL,NULL,NULL,5.00),
	(142,'rice',12,'king prawn',NULL,NULL,NULL,NULL,NULL,5.40),
	(143,'rice',12,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,4.90),

	(150,'rice',13,'chicken',NULL,NULL,NULL,NULL,NULL,5.50),
	(151,'rice',13,'king prawn',NULL,NULL,NULL,NULL,NULL,5.80);

INSERT INTO nb_item VALUES
	(160,'wokrice',14,'chicken',NULL,NULL,1,NULL,NULL,4.40),
	(161,'wokrice',14,'king prawn',NULL,NULL,NULL,NULL,NULL,4.70),
	(162,'wokrice',14,'noodlebar special','w chicken, pork & shrimp',NULL,NULL,NULL,NULL,4.70),
	(163,'wokrice',14,'singapore','spicy w chicken, pork, onion & shrimp',NULL,NULL,NULL,NULL,4.80),
	(164,'wokrice',14,'mushroom','w spring onion & cashew',NULL,NULL,1,1,4.30);

INSERT INTO nb_item VALUES
	(170,'extra',NULL,'noodles','w onion, carrot, sp/onion & b/sprout',NULL,NULL,1,NULL,3.10),
	(171,'extra',NULL,'just plain noodles','(no veg)',NULL,NULL,1,NULL,3.10),
	(172,'extra',NULL,'steamed rice',NULL,NULL,NULL,1,NULL,2.20),
	(173,'extra',NULL,'egg fried rice',NULL,NULL,NULL,1,NULL,2.90),
	(174,'extra',NULL,'fried mushrooms',NULL,NULL,NULL,1,NULL,2.20),
	(175,'extra',NULL,'beansprouts','w onion & spring onion',NULL,NULL,1,NULL,2.20),
	(176,'extra',NULL,'cashew nuts',NULL,NULL,NULL,1,1,0.60),
	(177,'extra',NULL,'fresh cut chili',NULL,NULL,NULL,1,NULL,0.30);

INSERT INTO nb_item VALUES
	(180,'sauce',NULL,'chinese curry sauce',NULL,NULL,NULL,1,NULL,1.00),
	(181,'sauce',NULL,'sweet and sour sauce',NULL,NULL,NULL,1,NULL,1.00),
	(182,'sauce',NULL,'satay sauce',NULL,NULL,NULL,1,1,1.00),
	(183,'sauce',NULL,'chinese gravy',NULL,NULL,NULL,1,NULL,1.00),
	(184,'sauce',NULL,'sweet chili dip',NULL,NULL,NULL,1,NULL,0.30),
	(185,'sauce',NULL,'hoi sin dip',NULL,NULL,NULL,1,NULL,0.30),
	(186,'sauce',NULL,'bbq dip',NULL,NULL,NULL,1,NULL,0.30),
	(187,'sauce',NULL,'chili oil',NULL,NULL,NULL,NULL,NULL,0.30);

/* SELECT * FROM nb_item left join nb_option ON nb_item.type = nb_option.type; */


