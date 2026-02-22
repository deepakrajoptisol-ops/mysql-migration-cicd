-- MySQL dump 10.13  Distrib 8.0.44, for Linux (x86_64)
--
-- Host: sql12.freesqldatabase.com    Database: sql12817767
-- ------------------------------------------------------
-- Server version	5.5.62-0ubuntu0.14.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `DATABASECHANGELOG`
--

DROP TABLE IF EXISTS `DATABASECHANGELOG`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DATABASECHANGELOG` (
  `ID` varchar(255) NOT NULL,
  `AUTHOR` varchar(255) NOT NULL,
  `FILENAME` varchar(500) NOT NULL,
  `DATEEXECUTED` datetime NOT NULL,
  `ORDEREXECUTED` int(11) NOT NULL,
  `EXECTYPE` varchar(10) NOT NULL,
  `MD5SUM` char(64) DEFAULT NULL,
  `DESCRIPTION` varchar(255) DEFAULT NULL,
  `COMMENTS` text,
  `LABELS` varchar(255) DEFAULT NULL,
  `CONTEXTS` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID`,`AUTHOR`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DATABASECHANGELOG`
--

LOCK TABLES `DATABASECHANGELOG` WRITE;
/*!40000 ALTER TABLE `DATABASECHANGELOG` DISABLE KEYS */;
INSERT INTO `DATABASECHANGELOG` VALUES ('001','deepakrajoptisol-ops','migrations/001_table named version 1 created.up.sql','2026-02-22 09:55:03',3,'EXECUTED','03d5d849112383e863e7f89fc42edf5a18b2953e236b2b46ccc1a4a65145e4e4',NULL,NULL,'web-upload','dev,prod'),('009','deepakrajoptisol-ops','migrations/009_table named version 1 created.up.sql','2026-02-22 09:44:49',1,'EXECUTED','45574aa36d1420440770abe1c395e99b2635551bcaeb7a0ca352450eda10bf08',NULL,NULL,'web-upload','dev,prod'),('10','deepakrajoptisol-ops','migrations/10_table named version 1 created.up.sql','2026-02-22 09:44:51',2,'EXECUTED','a1de5f258194b7496e0d3deac894488faa04661d955ab2e8ae6c7bf68b44ede9',NULL,NULL,'web-upload','dev,prod');
/*!40000 ALTER TABLE `DATABASECHANGELOG` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DATABASECHANGELOGLOCK`
--

DROP TABLE IF EXISTS `DATABASECHANGELOGLOCK`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DATABASECHANGELOGLOCK` (
  `ID` int(11) NOT NULL,
  `LOCKED` tinyint(1) NOT NULL DEFAULT '0',
  `LOCKGRANTED` datetime DEFAULT NULL,
  `LOCKEDBY` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DATABASECHANGELOGLOCK`
--

LOCK TABLES `DATABASECHANGELOGLOCK` WRITE;
/*!40000 ALTER TABLE `DATABASECHANGELOGLOCK` DISABLE KEYS */;
INSERT INTO `DATABASECHANGELOGLOCK` VALUES (1,0,NULL,NULL);
/*!40000 ALTER TABLE `DATABASECHANGELOGLOCK` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mytable`
--

DROP TABLE IF EXISTS `mytable`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mytable` (
  `id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `created_at` date DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mytable`
--

LOCK TABLES `mytable` WRITE;
/*!40000 ALTER TABLE `mytable` DISABLE KEYS */;
/*!40000 ALTER TABLE `mytable` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mytable2`
--

DROP TABLE IF EXISTS `mytable2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mytable2` (
  `id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `created_at` date DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mytable2`
--

LOCK TABLES `mytable2` WRITE;
/*!40000 ALTER TABLE `mytable2` DISABLE KEYS */;
/*!40000 ALTER TABLE `mytable2` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ops_migration_runs`
--

DROP TABLE IF EXISTS `ops_migration_runs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ops_migration_runs` (
  `run_id` char(36) NOT NULL,
  `env_name` varchar(32) NOT NULL,
  `git_sha` char(40) DEFAULT NULL,
  `actor` varchar(128) DEFAULT NULL,
  `started_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `finished_at` timestamp NULL DEFAULT NULL,
  `status` enum('running','succeeded','failed','rolled_back') NOT NULL,
  `backup_ref` varchar(512) DEFAULT NULL,
  `error_message` text,
  `details` longtext,
  PRIMARY KEY (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ops_migration_runs`
--

LOCK TABLES `ops_migration_runs` WRITE;
/*!40000 ALTER TABLE `ops_migration_runs` DISABLE KEYS */;
INSERT INTO `ops_migration_runs` VALUES ('23b14e19-f977-4e54-886f-6092f70e7396','dev','68b83f6e243bee166a560ed2d339a5e48205a590','deepakrajoptisol-ops','2026-02-22 17:54:59','2026-02-22 17:55:04','succeeded','backup_pre_migration_20260222T175245Z.sql',NULL,NULL),('b54093e6-3a00-4796-b749-fbcb1c4baabf','dev','b1cd77e8f22697d1418199a6fdccd8df07264900','deepakrajoptisol-ops','2026-02-22 16:56:30','2026-02-22 16:56:34','failed','backup_pre_migration_20260222T165426Z.sql','Changeset \'001\' failed: 1050 (42S01): Table \'mytable\' already exists',NULL),('c4f8540d-41b5-407c-aa1d-da29b1b7d7d9','dev','aa7fc64f94b597a44a18108150d43e2e0d7173b0','deepakrajoptisol-ops','2026-02-22 17:44:45','2026-02-22 17:44:52','succeeded','backup_pre_migration_20260222T174235Z.sql',NULL,NULL);
/*!40000 ALTER TABLE `ops_migration_runs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sample`
--

DROP TABLE IF EXISTS `sample`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sample` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sample`
--

LOCK TABLES `sample` WRITE;
/*!40000 ALTER TABLE `sample` DISABLE KEYS */;
/*!40000 ALTER TABLE `sample` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sample1`
--

DROP TABLE IF EXISTS `sample1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sample1` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sample1`
--

LOCK TABLES `sample1` WRITE;
/*!40000 ALTER TABLE `sample1` DISABLE KEYS */;
/*!40000 ALTER TABLE `sample1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sample2`
--

DROP TABLE IF EXISTS `sample2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sample2` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sample2`
--

LOCK TABLES `sample2` WRITE;
/*!40000 ALTER TABLE `sample2` DISABLE KEYS */;
/*!40000 ALTER TABLE `sample2` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-22 18:04:28
