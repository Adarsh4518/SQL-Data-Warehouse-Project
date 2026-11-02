
/*
===============================================================================
Create Database and Schemas
===============================================================================

Script Purpose:
    This script creates a new database named 'DataWarehouse'
    and three additional databases named 'Bronze', 'Silver',
    and 'Gold'.

    These databases represent the three layers of the
    data warehouse architecture.

    Bronze : Raw data
    Silver : Cleaned and transformed data
    Gold   : Business-ready data for analytics

WARNING:
    This script uses IF NOT EXISTS, so existing databases
    will not be deleted or overwritten.
===============================================================================
*/

-- Create the main DataWarehouse database
CREATE DATABASE IF NOT EXISTS DataWarehouse;

-- Select the DataWarehouse database
USE DataWarehouse;

-- Create the Bronze, Silver and Gold databases
CREATE SCHEMA IF NOT EXISTS Bronze;
CREATE SCHEMA IF NOT EXISTS Silver;
CREATE SCHEMA IF NOT EXISTS Gold;
