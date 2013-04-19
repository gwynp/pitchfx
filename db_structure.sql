-- MySQL dump 10.13  Distrib 5.5.29, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: pitchfx2
-- ------------------------------------------------------
-- Server version	5.5.29-0ubuntu0.12.10.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `atbats`
--

DROP TABLE IF EXISTS `atbats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `atbats` (
  `ab_id` mediumint(9) unsigned NOT NULL AUTO_INCREMENT,
  `game_id` smallint(6) unsigned NOT NULL,
  `inning` tinyint(2) unsigned NOT NULL,
  `half` tinyint(1) unsigned DEFAULT '0',
  `num` tinyint(3) unsigned NOT NULL,
  `ball` tinyint(1) unsigned NOT NULL,
  `strike` tinyint(1) unsigned NOT NULL,
  `outs` tinyint(1) unsigned NOT NULL,
  `batter` mediumint(6) unsigned NOT NULL,
  `pitcher` mediumint(6) unsigned NOT NULL,
  `stand` varchar(1) NOT NULL,
  `des` varchar(400) NOT NULL,
  `event` varchar(50) NOT NULL,
  `hit_x` float DEFAULT NULL,
  `hit_y` float DEFAULT NULL,
  `hit_type` varchar(1) DEFAULT NULL,
  `bbtype` varchar(2) DEFAULT NULL,
  `pitcher_seq` int(2) unsigned NOT NULL,
  `pitcher_ab_seq` int(2) unsigned NOT NULL,
  `def2` mediumint(6) unsigned NOT NULL,
  `def3` mediumint(6) unsigned NOT NULL,
  `def4` mediumint(6) unsigned NOT NULL,
  `def5` mediumint(6) unsigned NOT NULL,
  `def6` mediumint(6) unsigned NOT NULL,
  `def7` mediumint(6) unsigned NOT NULL,
  `def8` mediumint(6) unsigned NOT NULL,
  `def9` mediumint(6) unsigned NOT NULL,
  PRIMARY KEY (`ab_id`),
  KEY `game_id` (`game_id`),
  KEY `num` (`num`)
) ENGINE=MyISAM AUTO_INCREMENT=1074950 DEFAULT CHARSET=latin1 COMMENT='Play-by-play data';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `game_types`
--

DROP TABLE IF EXISTS `game_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `game_types` (
  `id` tinyint(3) unsigned NOT NULL,
  `type` varchar(25) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `games`
--

DROP TABLE IF EXISTS `games`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `games` (
  `game_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `home` varchar(7) NOT NULL,
  `away` varchar(7) NOT NULL,
  `game` tinyint(3) unsigned NOT NULL,
  `umpire` varchar(30) DEFAULT NULL,
  `wind` tinyint(4) unsigned DEFAULT NULL,
  `wind_dir` varchar(20) DEFAULT NULL,
  `temp` tinyint(4) DEFAULT NULL,
  `type` varchar(7) DEFAULT NULL,
  `runs_home` tinyint(3) unsigned DEFAULT NULL,
  `runs_away` tinyint(3) unsigned DEFAULT NULL,
  `local_time` time DEFAULT NULL,
  PRIMARY KEY (`game_id`)
) ENGINE=MyISAM AUTO_INCREMENT=14124 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pitch_types`
--

DROP TABLE IF EXISTS `pitch_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pitch_types` (
  `id` tinyint(2) NOT NULL,
  `pitch` varchar(25) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COMMENT='list of pitch types';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pitches`
--

DROP TABLE IF EXISTS `pitches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pitches` (
  `pitch_id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `ab_id` mediumint(8) unsigned NOT NULL,
  `des` varchar(30) NOT NULL,
  `type` varchar(1) NOT NULL,
  `id` smallint(5) unsigned NOT NULL,
  `x` float unsigned NOT NULL,
  `y` float unsigned NOT NULL,
  `start_speed` float unsigned DEFAULT NULL,
  `end_speed` float unsigned DEFAULT NULL,
  `sz_top` float unsigned DEFAULT NULL,
  `sz_bot` float unsigned DEFAULT NULL,
  `pfx_x` float DEFAULT NULL,
  `pfx_z` float DEFAULT NULL,
  `px` float DEFAULT NULL,
  `pz` float DEFAULT NULL,
  `x0` float DEFAULT NULL,
  `y0` float DEFAULT NULL,
  `z0` float DEFAULT NULL,
  `vx0` float DEFAULT NULL,
  `vy0` float DEFAULT NULL,
  `vz0` float DEFAULT NULL,
  `ax` float DEFAULT NULL,
  `ay` float DEFAULT NULL,
  `az` float DEFAULT NULL,
  `break_y` float DEFAULT NULL,
  `break_angle` float DEFAULT NULL,
  `break_length` float DEFAULT NULL,
  `ball` tinyint(3) unsigned DEFAULT NULL,
  `strike` tinyint(3) unsigned DEFAULT NULL,
  `on_1b` mediumint(8) unsigned DEFAULT NULL,
  `on_2b` mediumint(8) unsigned DEFAULT NULL,
  `on_3b` mediumint(8) unsigned DEFAULT NULL,
  `sv_id` varchar(13) DEFAULT NULL,
  `pitch_type` varchar(2) DEFAULT NULL,
  `type_confidence` double DEFAULT NULL,
  `my_pitch_type` tinyint(2) DEFAULT NULL,
  `nasty` tinyint(3) unsigned DEFAULT NULL,
  `cc` varchar(300) DEFAULT NULL,
  `pitch_seq` int(3) unsigned NOT NULL,
  PRIMARY KEY (`pitch_id`),
  KEY `ab_id` (`ab_id`)
) ENGINE=MyISAM AUTO_INCREMENT=3899837 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `players` (
  `eliasid` mediumint(6) unsigned NOT NULL,
  `first` varchar(20) NOT NULL,
  `last` varchar(20) NOT NULL,
  `lahmanid` varchar(10) DEFAULT NULL,
  `throws` varchar(1) DEFAULT NULL,
  `height` tinyint(3) unsigned DEFAULT NULL,
  PRIMARY KEY (`eliasid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COMMENT='MLB Player IDs and names';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `umpires`
--

DROP TABLE IF EXISTS `umpires`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `umpires` (
  `ump_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `first` varchar(20) NOT NULL,
  `last` varchar(20) NOT NULL,
  PRIMARY KEY (`ump_id`)
) ENGINE=MyISAM AUTO_INCREMENT=172 DEFAULT CHARSET=latin1 COMMENT='Home plate umpire names';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-04-19  9:12:50
