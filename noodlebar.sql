-- MySQL dump 10.9
--
-- Host: 127.0.0.1    Database: nicolaw
-- ------------------------------------------------------
-- Server version	4.1.14-standard

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `nb_type`
--

DROP TABLE IF EXISTS `nb_type`;
CREATE TABLE `nb_type` (
  `type` enum('noodles','soup','rice') NOT NULL default 'noodles',
  `variant` varchar(12) NOT NULL default '',
  `description` varchar(128) NOT NULL default '',
  `suppliment` decimal(5,2) default NULL,
  PRIMARY KEY  (`type`,`variant`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `nb_type`
--


/*!40000 ALTER TABLE `nb_type` DISABLE KEYS */;
LOCK TABLES `nb_type` WRITE;
INSERT INTO `nb_type` VALUES ('noodles','yo min','medium chinese egg and wheat noodles',NULL);
INSERT INTO `nb_type` VALUES ('noodles','udon','thick japenese wheat flour noodles',NULL);
INSERT INTO `nb_type` VALUES ('noodles','ho fun','think, flat chinese rice flour noodles',NULL);
INSERT INTO `nb_type` VALUES ('noodles','mai fun','fine vermicelli rice flour noodles',NULL);
INSERT INTO `nb_type` VALUES ('soup','mai fun','fine vermicelli rice flour noodles',NULL);
INSERT INTO `nb_type` VALUES ('soup','udon','thick japenese wheat flour noodles',NULL);
INSERT INTO `nb_type` VALUES ('soup','ho fun','think, flat chinese rice flour noodles',NULL);
INSERT INTO `nb_type` VALUES ('rice','steamed','steamed rice',NULL);
INSERT INTO `nb_type` VALUES ('rice','egg-fried','egg-fried rice',NULL);
INSERT INTO `nb_type` VALUES ('rice','yo min','medium chinese egg and wheat noodles','0.60');
INSERT INTO `nb_type` VALUES ('rice','udon','thick japenese wheat flour noodles','0.60');
INSERT INTO `nb_type` VALUES ('rice','ho fun','think, flat chinese rice flour noodles','0.60');
INSERT INTO `nb_type` VALUES ('rice','mai fun','fine vermicelli rice flour noodles','0.60');
UNLOCK TABLES;
/*!40000 ALTER TABLE `nb_type` ENABLE KEYS */;

--
-- Table structure for table `nb_item`
--

DROP TABLE IF EXISTS `nb_item`;
CREATE TABLE `nb_item` (
  `item_id` smallint(5) unsigned NOT NULL default '0',
  `type` enum('noodles','soup','rice','wokrice','side','sauce','extra') NOT NULL default 'noodles',
  `style_id` smallint(5) unsigned default NULL,
  `title` varchar(48) NOT NULL default '',
  `info` varchar(128) default NULL,
  `qty` tinyint(3) unsigned default NULL,
  `children` tinyint(1) default NULL,
  `vegetarian` tinyint(1) default NULL,
  `nuts` tinyint(1) default NULL,
  `price` decimal(5,2) default NULL,
  PRIMARY KEY  (`item_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `nb_item`
--


/*!40000 ALTER TABLE `nb_item` DISABLE KEYS */;
LOCK TABLES `nb_item` WRITE;
INSERT INTO `nb_item` VALUES (1,'side',NULL,'small prawn crackers','good for 1 or 2',NULL,NULL,NULL,NULL,'0.80');
INSERT INTO `nb_item` VALUES (2,'side',NULL,'large prawn crackers','for 2 or more',NULL,NULL,NULL,NULL,'1.20');
INSERT INTO `nb_item` VALUES (3,'side',NULL,'vegetarian spring rolls','w sweet chili dip',6,NULL,1,NULL,'2.20');
INSERT INTO `nb_item` VALUES (4,'side',NULL,'crispy \'seaweed\'','w dried shrimp seasoning',NULL,NULL,NULL,NULL,'2.20');
INSERT INTO `nb_item` VALUES (5,'side',NULL,'crispy coated chicken wings',NULL,NULL,NULL,NULL,NULL,'3.30');
INSERT INTO `nb_item` VALUES (6,'side',NULL,'tempura battered vegetables','w sweet chili dip (green bean, carrots, cauliflower & peppers)',NULL,NULL,1,NULL,'3.30');
INSERT INTO `nb_item` VALUES (7,'side',NULL,'wok fried mixed vegetables & cashews','(onion, spring onion, chinese leaf, b/sprout, m/room, babycorn, carrot, cashew, peas, peppers & garlic)',NULL,NULL,1,1,'3.30');
INSERT INTO `nb_item` VALUES (8,'side',NULL,'tempura battered king prawns',NULL,4,NULL,NULL,NULL,'3.30');
INSERT INTO `nb_item` VALUES (9,'side',NULL,'sesame prawn toast',NULL,NULL,NULL,NULL,NULL,'3.30');
INSERT INTO `nb_item` VALUES (10,'side',NULL,'deep fried ribs','w bbq dip',NULL,NULL,NULL,NULL,'3.30');
INSERT INTO `nb_item` VALUES (11,'side',NULL,'chicken satay skewers','w spicy peanut sauce',5,NULL,NULL,1,'3.60');
INSERT INTO `nb_item` VALUES (12,'side',NULL,'seared vegetable dumplings','w spiced soy dip',4,NULL,1,NULL,'3.60');
INSERT INTO `nb_item` VALUES (13,'side',NULL,'seared meat dumplings','w spiced soy dip',4,NULL,NULL,NULL,'3.60');
INSERT INTO `nb_item` VALUES (14,'side',NULL,'salt & pepper ribs','w chili & garlic',NULL,NULL,NULL,NULL,'3.60');
INSERT INTO `nb_item` VALUES (15,'side',NULL,'tom yum prawns','in coriander & lemongrass batter w sweet chili dip',NULL,NULL,NULL,NULL,'3.60');
INSERT INTO `nb_item` VALUES (16,'side',NULL,'bak choi','w vegetarian \'oyster\' sauce',NULL,NULL,1,NULL,'3.60');
INSERT INTO `nb_item` VALUES (17,'side',NULL,'salt & pepper squid','w chili & garlic',NULL,NULL,NULL,NULL,'3.80');
INSERT INTO `nb_item` VALUES (18,'side',NULL,'sticky cantonese ribs','in a sweet rich tomato sauce',NULL,NULL,NULL,NULL,'3.80');
INSERT INTO `nb_item` VALUES (19,'side',NULL,'thai fish skewers','boneless cod fillet',4,NULL,NULL,NULL,'3.80');
INSERT INTO `nb_item` VALUES (20,'side',NULL,'duck spring rolls','w hoi sin dip',2,NULL,NULL,NULL,'3.80');
INSERT INTO `nb_item` VALUES (30,'noodles',1,'chicken',NULL,NULL,1,NULL,NULL,'4.90');
INSERT INTO `nb_item` VALUES (31,'noodles',1,'beef',NULL,NULL,NULL,NULL,NULL,'4.90');
INSERT INTO `nb_item` VALUES (32,'noodles',1,'roast \'cha  sui\' pork',NULL,NULL,NULL,NULL,NULL,'5.10');
INSERT INTO `nb_item` VALUES (33,'noodles',1,'roast duck',NULL,NULL,NULL,NULL,NULL,'5.10');
INSERT INTO `nb_item` VALUES (34,'noodles',1,'mixed roast ruck & pork',NULL,NULL,NULL,NULL,NULL,'5.10');
INSERT INTO `nb_item` VALUES (35,'noodles',1,'mixed vegetable & cashew','additional chinese leaf, peas, babycorn, m/room, cashew & peppers',NULL,NULL,1,1,'4.90');
INSERT INTO `nb_item` VALUES (36,'noodles',1,'mixed meat','w beef balls, chicken, pork & roast duck',NULL,NULL,NULL,NULL,'5.20');
INSERT INTO `nb_item` VALUES (37,'noodles',1,'king prawn',NULL,NULL,NULL,NULL,NULL,'5.40');
INSERT INTO `nb_item` VALUES (38,'noodles',1,'seafood','w prawn, mussel, squid, \'crab\' & peppers',NULL,NULL,NULL,NULL,'5.50');
INSERT INTO `nb_item` VALUES (39,'noodles',1,'singapore','spicy w chicken, pork, shrimp & peppers',NULL,NULL,NULL,NULL,'5.40');
INSERT INTO `nb_item` VALUES (40,'noodles',1,'vegetarian singapore','spicy version of our mixed vegetable and cashew',NULL,NULL,1,1,'5.20');
INSERT INTO `nb_item` VALUES (41,'soup',2,'chicken',NULL,NULL,NULL,NULL,NULL,'4.90');
INSERT INTO `nb_item` VALUES (42,'soup',2,'beef',NULL,NULL,NULL,NULL,NULL,'4.90');
INSERT INTO `nb_item` VALUES (43,'soup',2,'roast \'cha sui\' pork',NULL,NULL,NULL,NULL,NULL,'5.10');
INSERT INTO `nb_item` VALUES (44,'soup',2,'roast duck',NULL,NULL,NULL,NULL,NULL,'5.10');
INSERT INTO `nb_item` VALUES (45,'soup',2,'mixed roast duck & pork',NULL,NULL,NULL,NULL,NULL,'5.10');
INSERT INTO `nb_item` VALUES (46,'soup',2,'mixed vegetable','onion, spring onion, chinese leaf, b/sprout, peas, baby corn, carrot, cashew, m/room & peppers',NULL,NULL,1,1,'4.90');
INSERT INTO `nb_item` VALUES (47,'soup',2,'seafood','w prawns, mussels, squid, \'crab\' sticks, fishballs',NULL,NULL,NULL,NULL,'5.50');
INSERT INTO `nb_item` VALUES (48,'soup',2,'wonton','freshly made traditional pork & prawn raviloi',NULL,NULL,NULL,NULL,'5.50');
INSERT INTO `nb_item` VALUES (50,'rice',3,'chicken & mushroom',NULL,NULL,1,NULL,NULL,'4.90');
INSERT INTO `nb_item` VALUES (51,'rice',3,'beef & mushroom',NULL,NULL,NULL,NULL,NULL,'4.90');
INSERT INTO `nb_item` VALUES (52,'rice',3,'chicken & pineapple',NULL,NULL,NULL,NULL,NULL,'4.90');
INSERT INTO `nb_item` VALUES (53,'rice',3,'king prawn & pineapple',NULL,NULL,1,NULL,NULL,'5.30');
INSERT INTO `nb_item` VALUES (54,'rice',3,'mixed meat & vegetable','w pork, prawn, beef, chicken & duck',NULL,NULL,NULL,NULL,'5.30');
INSERT INTO `nb_item` VALUES (60,'rice',4,'chicken balls in batter',NULL,NULL,1,NULL,NULL,'4.90');
INSERT INTO `nb_item` VALUES (61,'rice',4,'hong kong style crispy coated chicken',NULL,NULL,1,NULL,NULL,'5.00');
INSERT INTO `nb_item` VALUES (62,'rice',4,'hong kong style crispy coated king prawn',NULL,NULL,NULL,NULL,NULL,'5.30');
INSERT INTO `nb_item` VALUES (63,'rice',4,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,'4.90');
INSERT INTO `nb_item` VALUES (70,'rice',5,'chicken',NULL,NULL,NULL,NULL,NULL,'5.00');
INSERT INTO `nb_item` VALUES (71,'rice',5,'beef',NULL,NULL,NULL,NULL,NULL,'5.00');
INSERT INTO `nb_item` VALUES (72,'rice',5,'roast duck',NULL,NULL,NULL,NULL,NULL,'5.30');
INSERT INTO `nb_item` VALUES (73,'rice',5,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,'4.90');
INSERT INTO `nb_item` VALUES (74,'rice',5,'king prawn',NULL,NULL,NULL,NULL,NULL,'5.40');
INSERT INTO `nb_item` VALUES (75,'rice',5,'seafood','w prawn, mussel, squid, \'crab\' sticks & fishballs',NULL,NULL,NULL,NULL,'5.50');
INSERT INTO `nb_item` VALUES (80,'rice',6,'chicken',NULL,NULL,NULL,NULL,NULL,'4.90');
INSERT INTO `nb_item` VALUES (81,'rice',6,'beef',NULL,NULL,NULL,NULL,NULL,'4.90');
INSERT INTO `nb_item` VALUES (82,'rice',6,'king prawn',NULL,NULL,NULL,NULL,NULL,'5.30');
INSERT INTO `nb_item` VALUES (83,'rice',6,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,'4.90');
INSERT INTO `nb_item` VALUES (84,'rice',6,'noodlebar special','w chicken, beef, king prawn, duck and cha sui pork',NULL,NULL,NULL,NULL,'5.40');
INSERT INTO `nb_item` VALUES (90,'rice',7,'chicken',NULL,NULL,NULL,NULL,1,'5.00');
INSERT INTO `nb_item` VALUES (91,'rice',7,'beef',NULL,NULL,NULL,NULL,1,'5.00');
INSERT INTO `nb_item` VALUES (92,'rice',7,'king prawn',NULL,NULL,NULL,NULL,1,'5.40');
INSERT INTO `nb_item` VALUES (93,'rice',7,'mixed vegetable',NULL,NULL,NULL,1,1,'4.90');
INSERT INTO `nb_item` VALUES (100,'rice',8,'chicken',NULL,NULL,NULL,NULL,NULL,'5.00');
INSERT INTO `nb_item` VALUES (101,'rice',8,'king prawn',NULL,NULL,NULL,NULL,NULL,'5.40');
INSERT INTO `nb_item` VALUES (102,'rice',8,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,'4.90');
INSERT INTO `nb_item` VALUES (110,'rice',9,'sticky coated chicken',NULL,NULL,NULL,NULL,1,'5.20');
INSERT INTO `nb_item` VALUES (111,'rice',9,'sticky coated king prawn',NULL,NULL,NULL,NULL,1,'5.60');
INSERT INTO `nb_item` VALUES (112,'rice',9,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,'5.10');
INSERT INTO `nb_item` VALUES (113,'rice',9,'sticky \'chili\' beef strips','w carrot only',NULL,NULL,NULL,1,'5.20');
INSERT INTO `nb_item` VALUES (120,'rice',10,'roast cha sui pork',NULL,NULL,NULL,NULL,NULL,'5.20');
INSERT INTO `nb_item` VALUES (121,'rice',10,'roast duck',NULL,NULL,NULL,NULL,NULL,'5.20');
INSERT INTO `nb_item` VALUES (122,'rice',10,'mixed roast duck & cha sui pork',NULL,NULL,NULL,NULL,NULL,'5.20');
INSERT INTO `nb_item` VALUES (130,'rice',11,'chicken',NULL,NULL,NULL,NULL,NULL,'5.00');
INSERT INTO `nb_item` VALUES (131,'rice',11,'beef',NULL,NULL,NULL,NULL,NULL,'5.00');
INSERT INTO `nb_item` VALUES (132,'rice',11,'king prawn',NULL,NULL,NULL,NULL,NULL,'5.40');
INSERT INTO `nb_item` VALUES (140,'rice',12,'chicken',NULL,NULL,NULL,NULL,NULL,'5.00');
INSERT INTO `nb_item` VALUES (141,'rice',12,'beef',NULL,NULL,NULL,NULL,NULL,'5.00');
INSERT INTO `nb_item` VALUES (142,'rice',12,'king prawn',NULL,NULL,NULL,NULL,NULL,'5.40');
INSERT INTO `nb_item` VALUES (143,'rice',12,'mixed vegetable & cashew',NULL,NULL,NULL,1,1,'4.90');
INSERT INTO `nb_item` VALUES (150,'rice',13,'chicken',NULL,NULL,NULL,NULL,NULL,'5.50');
INSERT INTO `nb_item` VALUES (151,'rice',13,'king prawn',NULL,NULL,NULL,NULL,NULL,'5.80');
INSERT INTO `nb_item` VALUES (160,'wokrice',14,'chicken',NULL,NULL,1,NULL,NULL,'4.40');
INSERT INTO `nb_item` VALUES (161,'wokrice',14,'king prawn',NULL,NULL,NULL,NULL,NULL,'4.70');
INSERT INTO `nb_item` VALUES (162,'wokrice',14,'noodlebar special','w chicken, pork & shrimp',NULL,NULL,NULL,NULL,'4.70');
INSERT INTO `nb_item` VALUES (163,'wokrice',14,'singapore','spicy w chicken, pork, onion & shrimp',NULL,NULL,NULL,NULL,'4.80');
INSERT INTO `nb_item` VALUES (164,'wokrice',14,'mushroom','w spring onion & cashew',NULL,NULL,1,1,'4.30');
INSERT INTO `nb_item` VALUES (170,'extra',NULL,'noodles','w onion, carrot, sp/onion & b/sprout',NULL,NULL,1,NULL,'3.10');
INSERT INTO `nb_item` VALUES (171,'extra',NULL,'just plain noodles','(no veg)',NULL,NULL,1,NULL,'3.10');
INSERT INTO `nb_item` VALUES (172,'extra',NULL,'steamed rice',NULL,NULL,NULL,1,NULL,'2.20');
INSERT INTO `nb_item` VALUES (173,'extra',NULL,'egg fried rice',NULL,NULL,NULL,1,NULL,'2.90');
INSERT INTO `nb_item` VALUES (174,'extra',NULL,'fried mushrooms',NULL,NULL,NULL,1,NULL,'2.20');
INSERT INTO `nb_item` VALUES (175,'extra',NULL,'beansprouts','w onion & spring onion',NULL,NULL,1,NULL,'2.20');
INSERT INTO `nb_item` VALUES (176,'extra',NULL,'cashew nuts',NULL,NULL,NULL,1,1,'0.60');
INSERT INTO `nb_item` VALUES (177,'extra',NULL,'fresh cut chili',NULL,NULL,NULL,1,NULL,'0.30');
INSERT INTO `nb_item` VALUES (180,'sauce',NULL,'chinese curry sauce',NULL,NULL,NULL,1,NULL,'1.00');
INSERT INTO `nb_item` VALUES (181,'sauce',NULL,'sweet and sour sauce',NULL,NULL,NULL,1,NULL,'1.00');
INSERT INTO `nb_item` VALUES (182,'sauce',NULL,'satay sauce',NULL,NULL,NULL,1,1,'1.00');
INSERT INTO `nb_item` VALUES (183,'sauce',NULL,'chinese gravy',NULL,NULL,NULL,1,NULL,'1.00');
INSERT INTO `nb_item` VALUES (184,'sauce',NULL,'sweet chili dip',NULL,NULL,NULL,1,NULL,'0.30');
INSERT INTO `nb_item` VALUES (185,'sauce',NULL,'hoi sin dip',NULL,NULL,NULL,1,NULL,'0.30');
INSERT INTO `nb_item` VALUES (186,'sauce',NULL,'bbq dip',NULL,NULL,NULL,1,NULL,'0.30');
INSERT INTO `nb_item` VALUES (187,'sauce',NULL,'chili oil',NULL,NULL,NULL,NULL,NULL,'0.30');
UNLOCK TABLES;
/*!40000 ALTER TABLE `nb_item` ENABLE KEYS */;

--
-- Table structure for table `nb_style`
--

DROP TABLE IF EXISTS `nb_style`;
CREATE TABLE `nb_style` (
  `style_id` smallint(5) unsigned NOT NULL auto_increment,
  `style` varchar(32) NOT NULL default '',
  `description` varchar(128) NOT NULL default '',
  PRIMARY KEY  (`style_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `nb_style`
--


/*!40000 ALTER TABLE `nb_style` DISABLE KEYS */;
LOCK TABLES `nb_style` WRITE;
INSERT INTO `nb_style` VALUES (1,'wok fried noodles','w onion, beansprout, carrot & spring onion, lightly seasoned w soy sauce');
INSERT INTO `nb_style` VALUES (2,'soup noodles','traditional clear, lightly seasoned chinese noodle soup, garnished w chinese leaf & spring onion');
INSERT INTO `nb_style` VALUES (3,'stir fry','light soy flavoured sauce w onion');
INSERT INTO `nb_style` VALUES (4,'sweet and sour','w onion, pineapple & peppers');
INSERT INTO `nb_style` VALUES (5,'blackbean','blackbean sauce w mild chili, onion & peppers');
INSERT INTO `nb_style` VALUES (6,'chinese curry','mild sauce w wok fried onion');
INSERT INTO `nb_style` VALUES (7,'yellowbean','sweet hoi sin & crushed ywlloebean sauce w onion, cashew & peppers');
INSERT INTO `nb_style` VALUES (8,'chili & garlic','spicy sauce w fresh chili, garlic, onion & peppers');
INSERT INTO `nb_style` VALUES (9,'kung po','sweet & tancy sauce made w orange, mild chili, pineapple, cashew & peppers');
INSERT INTO `nb_style` VALUES (10,'chinese roast gravy','w chinese leaf. spring onion garnish & gravy');
INSERT INTO `nb_style` VALUES (11,'cantonese','tangy, sweet sauce w tomato, onion & peppers');
INSERT INTO `nb_style` VALUES (12,'ginger & pring onion','w soy sauce, carror, sliced ginger & onion');
INSERT INTO `nb_style` VALUES (13,'malay curry','medium coconut curry w potato, baby corn & peas');
INSERT INTO `nb_style` VALUES (14,'wok fried rice','egg rice w sesame oil, soy sauce & garden peas');
UNLOCK TABLES;
/*!40000 ALTER TABLE `nb_style` ENABLE KEYS */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

