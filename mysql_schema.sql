-- MySQL dump 9.10
--
-- Host: localhost    Database: revmlweb
-- ------------------------------------------------------
-- Server version	4.0.18-standard

--
-- Table structure for table `count`
--

DROP TABLE IF EXISTS count;
CREATE TABLE count (
  countid int(11) NOT NULL auto_increment,
  revml int(11) default NULL,
  kind varchar(255) default NULL,
  event varchar(255) default NULL,
  counts int(11) default NULL,
  PRIMARY KEY  (countid)
) TYPE=MyISAM;

--
-- Dumping data for table `count`
--


--
-- Table structure for table `count_top10`
--

DROP TABLE IF EXISTS count_top10;
CREATE TABLE count_top10 (
  revml varchar(255) default NULL,
  kind varchar(255) default NULL,
  event varchar(255) default NULL,
  counts varchar(255) default NULL,
  KEY kind (kind)
) TYPE=MyISAM;

--
-- Dumping data for table `count_top10`
--


--
-- Table structure for table `developer`
--

DROP TABLE IF EXISTS developer;
CREATE TABLE developer (
  author varchar(255) default NULL,
  email varchar(255) NOT NULL default '',
  PRIMARY KEY  (email)
) TYPE=MyISAM;

--
-- Dumping data for table `developer`
--


--
-- Table structure for table `project`
--

DROP TABLE IF EXISTS project;
CREATE TABLE project (
  prjid int(11) NOT NULL auto_increment,
  name varchar(255) NOT NULL default '',
  PRIMARY KEY  (prjid)
) TYPE=MyISAM;

--
-- Dumping data for table `project`
--


--
-- Table structure for table `rev`
--

DROP TABLE IF EXISTS rev;
CREATE TABLE rev (
  rev varchar(255) binary NOT NULL default '',
  revml int(11) default NULL,
  author varchar(255) default NULL,
  target_path varchar(255) default NULL,
  comment text,
  PRIMARY KEY  (rev)
) TYPE=MyISAM;

--
-- Dumping data for table `rev`
--


--
-- Table structure for table `revml`
--

DROP TABLE IF EXISTS revml;
CREATE TABLE revml (
  revml int(11) NOT NULL auto_increment,
  prjid int(11) NOT NULL default '0',
  path varchar(255) default NULL,
  counted int(11) default NULL,
  graphed int(11) default NULL,
  PRIMARY KEY  (revml),
  UNIQUE KEY path (path)
) TYPE=MyISAM;

--
-- Dumping data for table `revml`
--


--
-- Table structure for table `statistic`
--

DROP TABLE IF EXISTS statistic;
CREATE TABLE statistic (
  sid   int(11) NOT NULL auto_increment,
  prjid int(11) NOT NULL,
  kind varchar(255) default NULL,
  event varchar(255) default NULL,
  counts varchar(255) default NULL,
  PRIMARY KEY kind (sid)
) TYPE=MyISAM;

--
-- Dumping data for table `statistic`
--


--
-- Table structure for table `statistic_top10`
--

DROP TABLE IF EXISTS statistic_top10;
CREATE TABLE statistic_top10 (
  revml varchar(255) default NULL,
  kind varchar(255) default NULL,
  event varchar(255) default NULL,
  counts varchar(255) default NULL,
  KEY kind (kind)
) TYPE=MyISAM;

--
-- Dumping data for table `statistic_top10`
--


