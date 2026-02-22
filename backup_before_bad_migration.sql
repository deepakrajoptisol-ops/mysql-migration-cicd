-- MySQL dump 10.13  Distrib 8.0.45, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: migration_db
-- ------------------------------------------------------
-- Server version	8.0.45

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
  `ORDEREXECUTED` int NOT NULL,
  `EXECTYPE` varchar(10) NOT NULL,
  `MD5SUM` char(64) DEFAULT NULL,
  `DESCRIPTION` varchar(255) DEFAULT NULL,
  `COMMENTS` text,
  `LABELS` varchar(255) DEFAULT NULL,
  `CONTEXTS` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID`,`AUTHOR`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DATABASECHANGELOG`
--

LOCK TABLES `DATABASECHANGELOG` WRITE;
/*!40000 ALTER TABLE `DATABASECHANGELOG` DISABLE KEYS */;
INSERT INTO `DATABASECHANGELOG` VALUES ('001','platform-team','migrations/001_initial_schema.up.sql','2026-02-22 10:54:14',1,'EXECUTED','a9c9a88f2e555b83107c6cb9e01b4d3d8b8a162c8b0fee0c2ad49c0811b0d43b',NULL,NULL,'schema,init','dev,prod'),('002','platform-team','migrations/002_add_indexes.up.sql','2026-02-22 10:54:14',2,'EXECUTED','65a89b5cae9b2b84e7b7862367eb4f86f032952a083c9d8291443e799e7ebb87',NULL,NULL,'performance','dev,prod'),('003','security-team','migrations/003_rbac_masking.up.sql','2026-02-22 10:54:14',3,'EXECUTED','fff5e8ff0bcde0d2b51e9da8d0ef29a285f84591e35775f0b1031230a1a8e6c3',NULL,NULL,'security,rbac','dev,prod'),('004','data-team','migrations/004_add_customer_segment.up.sql','2026-02-22 10:54:14',4,'EXECUTED','0da62c6278c51f9730e220a56be0d051d14e780d00a5060db42408d5a1ae979e',NULL,NULL,'feature,segmentation','dev,prod'),('005','product-team','migrations/005_add_order_priority.up.sql','2026-02-22 10:54:56',5,'EXECUTED','d92b63af3810688e1995489c660ccfa3f68bae4569c8bff1e7529f1000dd62dc',NULL,NULL,'feature,priority','dev,prod');
/*!40000 ALTER TABLE `DATABASECHANGELOG` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DATABASECHANGELOGLOCK`
--

DROP TABLE IF EXISTS `DATABASECHANGELOGLOCK`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DATABASECHANGELOGLOCK` (
  `ID` int NOT NULL,
  `LOCKED` tinyint(1) NOT NULL DEFAULT '0',
  `LOCKGRANTED` datetime DEFAULT NULL,
  `LOCKEDBY` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
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
-- Table structure for table `dim_customer`
--

DROP TABLE IF EXISTS `dim_customer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dim_customer` (
  `customer_sk` bigint NOT NULL AUTO_INCREMENT,
  `customer_id` bigint NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `email_masked` char(64) NOT NULL COMMENT 'SHA-256 hash of email for privacy',
  `country` char(2) NOT NULL,
  `effective_from` datetime NOT NULL,
  `effective_to` datetime DEFAULT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT '1',
  `customer_segment` varchar(20) NOT NULL DEFAULT 'Standard',
  PRIMARY KEY (`customer_sk`),
  KEY `idx_dim_cust_bk` (`customer_id`),
  KEY `idx_dim_cust_current` (`is_current`,`customer_id`),
  KEY `idx_dim_customer_segment` (`customer_segment`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dim_customer`
--

LOCK TABLES `dim_customer` WRITE;
/*!40000 ALTER TABLE `dim_customer` DISABLE KEYS */;
INSERT INTO `dim_customer` VALUES (1,1,'Ada Lovelace','e814ff3dc480a94c7ce9334062ec4733c75a002f4bcec0197f62ffea64059e2f','GB','2026-02-22 10:54:24',NULL,1,'Standard'),(2,2,'Grace Hopper','a460d7fa831915bb17b55b9151a5278e916f2de6480dc2171845c4b305620428','US','2026-02-22 10:54:24',NULL,1,'Standard'),(3,3,'Alan Turing','5adbc841c805fd0f9e357001780cd8b8d30761dbad167b68d6a50b4716e00902','GB','2026-02-22 10:54:24',NULL,1,'Standard'),(4,4,'Margaret Hamilton','059403530b63ea6d4bf5d53800da86fe5dc39969764872219180466533d0f98a','US','2026-02-22 10:54:24',NULL,1,'Standard'),(5,5,'Linus Torvalds','748dee946f693ae47533553e2f51e2c85c07d3c72d32731ea0eb245b464736ca','FI','2026-02-22 10:54:24',NULL,1,'Standard'),(6,6,'Guido van Rossum','25f94c0a77da17f73b0d310046f65add12b72d980524b76e746db87f20797b29','NL','2026-02-22 10:54:24',NULL,1,'Standard'),(7,7,'James Gosling','0136c3bbdc51d32412e58abded087e0e80b051aefc1d7da3fd702bd551ff47f4','CA','2026-02-22 10:54:24',NULL,1,'Standard'),(8,8,'Bjarne Stroustrup','05eba1279d5265ff6be43ed62eb1b8f30fb683c8e119c45429eb7afbf27fe142','DK','2026-02-22 10:54:24',NULL,1,'Standard'),(9,9,'Dennis Ritchie','0fe9702dcef8ff6045e662b0d46e30a38ed75e2d92c9d57372c4210181423bab','US','2026-02-22 10:54:24',NULL,1,'Standard'),(10,10,'Tim Berners-Lee','b197b0745542606dfa1c14e6d6a10828de377c4bc8958e0af73edf0d7e970188','GB','2026-02-22 10:54:24',NULL,1,'Standard');
/*!40000 ALTER TABLE `dim_customer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fact_order`
--

DROP TABLE IF EXISTS `fact_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fact_order` (
  `order_id` bigint NOT NULL,
  `customer_sk` bigint NOT NULL,
  `order_date` date NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `currency` char(3) NOT NULL,
  `status` varchar(20) NOT NULL,
  `load_run_id` char(36) NOT NULL,
  `priority` varchar(10) NOT NULL DEFAULT 'normal',
  PRIMARY KEY (`order_id`),
  KEY `idx_fact_order_date` (`order_date`),
  KEY `idx_fact_order_cust` (`customer_sk`),
  KEY `idx_fact_order_run` (`load_run_id`),
  KEY `idx_fact_order_date_cust` (`order_date`,`customer_sk`),
  KEY `idx_fact_order_status_date` (`status`,`order_date`,`amount`),
  KEY `idx_fact_order_priority` (`priority`,`order_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fact_order`
--

LOCK TABLES `fact_order` WRITE;
/*!40000 ALTER TABLE `fact_order` DISABLE KEYS */;
INSERT INTO `fact_order` VALUES (1001,1,'2026-01-20',250.00,'USD','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1002,2,'2026-01-20',175.50,'USD','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1003,3,'2026-01-21',320.00,'GBP','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1004,1,'2026-01-21',89.99,'USD','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1005,4,'2026-01-22',450.00,'USD','pending','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1006,5,'2026-01-22',120.00,'EUR','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1007,6,'2026-01-23',95.50,'EUR','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1008,2,'2026-01-23',210.00,'USD','cancelled','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1009,7,'2026-01-24',180.00,'CAD','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1010,8,'2026-01-24',340.00,'DKK','pending','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1011,9,'2026-01-25',500.00,'USD','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1012,10,'2026-01-25',275.00,'GBP','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1013,3,'2026-01-26',150.00,'GBP','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1014,1,'2026-01-26',620.00,'USD','completed','6e115e9a-954f-419d-9c70-ce3ec3197338','normal'),(1015,5,'2026-01-27',88.00,'EUR','pending','6e115e9a-954f-419d-9c70-ce3ec3197338','normal');
/*!40000 ALTER TABLE `fact_order` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ops_checkpoints`
--

DROP TABLE IF EXISTS `ops_checkpoints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ops_checkpoints` (
  `dataset_name` varchar(128) NOT NULL,
  `last_watermark` varchar(64) NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`dataset_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ops_checkpoints`
--

LOCK TABLES `ops_checkpoints` WRITE;
/*!40000 ALTER TABLE `ops_checkpoints` DISABLE KEYS */;
INSERT INTO `ops_checkpoints` VALUES ('customers','2026-01-19 17:00:00','2026-02-22 10:54:24'),('orders','2026-01-27 09:00:00','2026-02-22 10:54:24');
/*!40000 ALTER TABLE `ops_checkpoints` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ops_dq_results`
--

DROP TABLE IF EXISTS `ops_dq_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ops_dq_results` (
  `run_id` char(36) NOT NULL,
  `check_name` varchar(128) NOT NULL,
  `status` enum('pass','fail') NOT NULL,
  `metric_value` decimal(20,4) DEFAULT NULL,
  `threshold` decimal(20,4) DEFAULT NULL,
  `details` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`run_id`,`check_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ops_dq_results`
--

LOCK TABLES `ops_dq_results` WRITE;
/*!40000 ALTER TABLE `ops_dq_results` DISABLE KEYS */;
INSERT INTO `ops_dq_results` VALUES ('6e115e9a-954f-419d-9c70-ce3ec3197338','duplicate_order_ids','pass',0.0000,0.0000,'{\"rule\": \"order_id must be unique\"}','2026-02-22 10:54:24'),('6e115e9a-954f-419d-9c70-ce3ec3197338','fact_recon_count','pass',15.0000,15.0000,'{\"rule\": \"fact rows == joinable staging rows\"}','2026-02-22 10:54:24'),('6e115e9a-954f-419d-9c70-ce3ec3197338','negative_amounts','pass',0.0000,0.0000,'{\"rule\": \"order amount must be positive\"}','2026-02-22 10:54:24'),('6e115e9a-954f-419d-9c70-ce3ec3197338','null_required_fields','pass',0.0000,0.0000,'{\"rule\": \"full_name, email, country must be non-empty\"}','2026-02-22 10:54:24'),('6e115e9a-954f-419d-9c70-ce3ec3197338','orphan_orders','pass',0.0000,0.0000,'{\"rule\": \"every order must have a customer\"}','2026-02-22 10:54:24');
/*!40000 ALTER TABLE `ops_dq_results` ENABLE KEYS */;
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
  `details` json DEFAULT NULL,
  PRIMARY KEY (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ops_migration_runs`
--

LOCK TABLES `ops_migration_runs` WRITE;
/*!40000 ALTER TABLE `ops_migration_runs` DISABLE KEYS */;
INSERT INTO `ops_migration_runs` VALUES ('266709aa-72ca-43c0-a284-598922d7ed39','dev',NULL,'local','2026-02-22 10:54:56','2026-02-22 10:54:56','succeeded',NULL,NULL,NULL),('693178ff-7d57-424c-bc33-5d7679328d32','dev',NULL,'local','2026-02-22 10:55:19','2026-02-22 10:55:19','succeeded',NULL,NULL,NULL),('99127030-7bf4-4c8e-a149-2c5bade8210d','dev',NULL,'local','2026-02-22 10:54:14','2026-02-22 10:54:14','succeeded',NULL,NULL,NULL);
/*!40000 ALTER TABLE `ops_migration_runs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ops_pipeline_runs`
--

DROP TABLE IF EXISTS `ops_pipeline_runs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ops_pipeline_runs` (
  `run_id` char(36) NOT NULL,
  `env_name` varchar(32) NOT NULL,
  `started_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `finished_at` timestamp NULL DEFAULT NULL,
  `status` enum('running','succeeded','failed') NOT NULL,
  `git_sha` char(40) DEFAULT NULL,
  `actor` varchar(128) DEFAULT NULL,
  `details` json DEFAULT NULL,
  PRIMARY KEY (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ops_pipeline_runs`
--

LOCK TABLES `ops_pipeline_runs` WRITE;
/*!40000 ALTER TABLE `ops_pipeline_runs` DISABLE KEYS */;
INSERT INTO `ops_pipeline_runs` VALUES ('6e115e9a-954f-419d-9c70-ce3ec3197338','dev','2026-02-22 10:54:24','2026-02-22 10:54:24','succeeded',NULL,'local','{\"orders_ingested\": 15, \"customers_ingested\": 10}');
/*!40000 ALTER TABLE `ops_pipeline_runs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stg_customers`
--

DROP TABLE IF EXISTS `stg_customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stg_customers` (
  `customer_id` bigint NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `country` char(2) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL,
  `customer_segment` varchar(20) NOT NULL DEFAULT 'Standard',
  PRIMARY KEY (`customer_id`),
  KEY `idx_stg_customers_updated` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stg_customers`
--

LOCK TABLES `stg_customers` WRITE;
/*!40000 ALTER TABLE `stg_customers` DISABLE KEYS */;
INSERT INTO `stg_customers` VALUES (1,'Ada Lovelace','ada.lovelace@example.com','GB','2026-02-22 10:54:24','2026-01-15 08:00:00','Standard'),(2,'Grace Hopper','grace.hopper@example.com','US','2026-02-22 10:54:24','2026-01-15 09:00:00','Standard'),(3,'Alan Turing','alan.turing@example.com','GB','2026-02-22 10:54:24','2026-01-16 10:00:00','Standard'),(4,'Margaret Hamilton','margaret.hamilton@example.com','US','2026-02-22 10:54:24','2026-01-16 11:00:00','Standard'),(5,'Linus Torvalds','linus.torvalds@example.com','FI','2026-02-22 10:54:24','2026-01-17 12:00:00','Standard'),(6,'Guido van Rossum','guido.vanrossum@example.com','NL','2026-02-22 10:54:24','2026-01-17 13:00:00','Standard'),(7,'James Gosling','james.gosling@example.com','CA','2026-02-22 10:54:24','2026-01-18 14:00:00','Standard'),(8,'Bjarne Stroustrup','bjarne.stroustrup@example.com','DK','2026-02-22 10:54:24','2026-01-18 15:00:00','Standard'),(9,'Dennis Ritchie','dennis.ritchie@example.com','US','2026-02-22 10:54:24','2026-01-19 16:00:00','Standard'),(10,'Tim Berners-Lee','tim.bernerslee@example.com','GB','2026-02-22 10:54:24','2026-01-19 17:00:00','Standard');
/*!40000 ALTER TABLE `stg_customers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stg_orders`
--

DROP TABLE IF EXISTS `stg_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stg_orders` (
  `order_id` bigint NOT NULL,
  `customer_id` bigint NOT NULL,
  `order_date` date NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'USD',
  `status` varchar(20) NOT NULL DEFAULT 'pending',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL,
  `priority` varchar(10) NOT NULL DEFAULT 'normal',
  PRIMARY KEY (`order_id`),
  KEY `idx_stg_orders_customer` (`customer_id`),
  KEY `idx_stg_orders_date` (`order_date`),
  KEY `idx_stg_orders_updated` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stg_orders`
--

LOCK TABLES `stg_orders` WRITE;
/*!40000 ALTER TABLE `stg_orders` DISABLE KEYS */;
INSERT INTO `stg_orders` VALUES (1001,1,'2026-01-20',250.00,'USD','completed','2026-02-22 10:54:24','2026-01-20 10:00:00','normal'),(1002,2,'2026-01-20',175.50,'USD','completed','2026-02-22 10:54:24','2026-01-20 11:00:00','normal'),(1003,3,'2026-01-21',320.00,'GBP','completed','2026-02-22 10:54:24','2026-01-21 09:00:00','normal'),(1004,1,'2026-01-21',89.99,'USD','completed','2026-02-22 10:54:24','2026-01-21 14:00:00','normal'),(1005,4,'2026-01-22',450.00,'USD','pending','2026-02-22 10:54:24','2026-01-22 08:00:00','normal'),(1006,5,'2026-01-22',120.00,'EUR','completed','2026-02-22 10:54:24','2026-01-22 10:00:00','normal'),(1007,6,'2026-01-23',95.50,'EUR','completed','2026-02-22 10:54:24','2026-01-23 11:00:00','normal'),(1008,2,'2026-01-23',210.00,'USD','cancelled','2026-02-22 10:54:24','2026-01-23 12:00:00','normal'),(1009,7,'2026-01-24',180.00,'CAD','completed','2026-02-22 10:54:24','2026-01-24 09:00:00','normal'),(1010,8,'2026-01-24',340.00,'DKK','pending','2026-02-22 10:54:24','2026-01-24 15:00:00','normal'),(1011,9,'2026-01-25',500.00,'USD','completed','2026-02-22 10:54:24','2026-01-25 08:00:00','normal'),(1012,10,'2026-01-25',275.00,'GBP','completed','2026-02-22 10:54:24','2026-01-25 16:00:00','normal'),(1013,3,'2026-01-26',150.00,'GBP','completed','2026-02-22 10:54:24','2026-01-26 10:00:00','normal'),(1014,1,'2026-01-26',620.00,'USD','completed','2026-02-22 10:54:24','2026-01-26 14:00:00','normal'),(1015,5,'2026-01-27',88.00,'EUR','pending','2026-02-22 10:54:24','2026-01-27 09:00:00','normal');
/*!40000 ALTER TABLE `stg_orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `vw_customer_masked`
--

DROP TABLE IF EXISTS `vw_customer_masked`;
/*!50001 DROP VIEW IF EXISTS `vw_customer_masked`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_customer_masked` AS SELECT 
 1 AS `customer_sk`,
 1 AS `customer_id`,
 1 AS `full_name_masked`,
 1 AS `email_masked`,
 1 AS `country`,
 1 AS `effective_from`,
 1 AS `effective_to`,
 1 AS `is_current`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_order_summary`
--

DROP TABLE IF EXISTS `vw_order_summary`;
/*!50001 DROP VIEW IF EXISTS `vw_order_summary`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_order_summary` AS SELECT 
 1 AS `customer_id`,
 1 AS `country`,
 1 AS `order_month`,
 1 AS `order_count`,
 1 AS `total_amount`,
 1 AS `avg_amount`,
 1 AS `min_amount`,
 1 AS `max_amount`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'migration_db'
--

--
-- Dumping routines for database 'migration_db'
--

--
-- Final view structure for view `vw_customer_masked`
--

/*!50001 DROP VIEW IF EXISTS `vw_customer_masked`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_customer_masked` AS select `dim_customer`.`customer_sk` AS `customer_sk`,`dim_customer`.`customer_id` AS `customer_id`,concat(left(`dim_customer`.`full_name`,1),'***') AS `full_name_masked`,`dim_customer`.`email_masked` AS `email_masked`,`dim_customer`.`country` AS `country`,`dim_customer`.`effective_from` AS `effective_from`,`dim_customer`.`effective_to` AS `effective_to`,`dim_customer`.`is_current` AS `is_current` from `dim_customer` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_order_summary`
--

/*!50001 DROP VIEW IF EXISTS `vw_order_summary`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_order_summary` AS select `d`.`customer_id` AS `customer_id`,`d`.`country` AS `country`,date_format(`f`.`order_date`,'%Y-%m') AS `order_month`,count(0) AS `order_count`,sum(`f`.`amount`) AS `total_amount`,avg(`f`.`amount`) AS `avg_amount`,min(`f`.`amount`) AS `min_amount`,max(`f`.`amount`) AS `max_amount` from (`fact_order` `f` join `dim_customer` `d` on(((`d`.`customer_sk` = `f`.`customer_sk`) and (`d`.`is_current` = 1)))) group by `d`.`customer_id`,`d`.`country`,date_format(`f`.`order_date`,'%Y-%m') */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-22 16:26:02
