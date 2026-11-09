
# SQL Data Warehouse & Analytics Project

Building a modern data warehouse using MySQL, implementing ETL processes, data modelling, and SQL-based analytics.

## Project Overview

This project demonstrates the design and implementation of an end-to-end data warehouse using data from two source systems: **CRM (Customer Relationship Management)** and **ERP (Enterprise Resource Planning)**.

The objective is to consolidate raw sales, customer, and product data into a structured data warehouse, ensuring data quality and enabling business-driven analytical reporting.

The project follows the **Medallion Architecture (Bronze, Silver, and Gold)** to transform raw data into clean, enriched, and business-ready datasets.

---

## Data Warehouse Architecture

The project follows a three-layer Medallion Architecture.

![Data Warehouse Architecture](Docs/Data%20Architecture.png)

### 1. Bronze Layer – Raw Data
- Ingested raw CSV files into MySQL tables.
- Implemented batch processing and full-load ingestion.
- Used TRUNCATE and INSERT operations to reload source data.
- Maintained raw source data for downstream transformations.

### 2. Silver Layer – Data Transformation
- Cleaned and standardized raw data.
- Handled NULL values, duplicates, and inconsistent records.
- Applied data validation and quality checks.
- Integrated CRM and ERP datasets.
- Performed data enrichment and derived-column transformations.

### 3. Gold Layer – Business-Ready Data
- Created customer and product dimension views.
- Developed a sales fact view.
- Implemented a Star Schema for analytical querying.
- Established relationships between fact and dimension tables.

---

## Source Data Model (ERD)

The project integrates data from CRM and ERP source systems.

![Source Data Model](Docs/Data%20model.png)

### Data Sources

| Source | Description |
|---|---|
| CRM | Sales transactions, customer information, and product details. |
| ERP | Customer demographics, geographical information, and product categories. |

---

## ETL Architecture

The ETL process extracts data from source CSV files, loads it into the Bronze Layer, transforms it through the Silver Layer, and produces business-ready datasets in the Gold Layer.

![ETL Architecture](Docs/ETL%20Architecture.png)

---

## Gold Layer – Star Schema

The Gold Layer follows a Star Schema consisting of two dimension views and one fact view.

![Star Schema](Docs/Star%20Schema.png)

| Table | Description |
|---|---|
| `gold.dim_customers` | Customer demographic and geographic information. |
| `gold.dim_products` | Product details, categories, and attributes. |
| `gold.fact_sales` | Sales transactions, order details, and business metrics. |

### Relationships
- `fact_sales.customer_key` → `dim_customers.customer_key`
- `fact_sales.product_key` → `dim_products.product_key`

---

## Key Project Achievements

- Designed and implemented a three-layer data warehouse using MySQL.
- Built an end-to-end ETL workflow to integrate multiple source systems.
- Performed data cleaning, standardization, deduplication, and validation.
- Developed reusable SQL views for customer, product, and sales analysis.
- Designed a Star Schema with two dimension views and one fact view.
- Implemented data quality checks, including duplicate detection and referential integrity validation.
- Created data dictionaries, architecture diagrams, and technical documentation.

---

## Business Analytics

The Gold Layer provides a foundation for analysing:

- **Customer Behaviour:** Customer demographics, distribution, and purchasing patterns.
- **Product Performance:** Product categories, subcategories, and sales performance.
- **Sales Trends:** Revenue, order quantities, pricing, and sales patterns.

---

## Tools & Technologies

- **Database:** MySQL
- **Database Management:** MySQL Workbench
- **Query Language:** SQL
- **Data Sources:** CSV Files
- **Data Modelling & Documentation:** Draw.io
- **Version Control:** Git & GitHub

---

## Project Documentation

Architecture diagrams, data models, data dictionaries, and technical documentation are available in the `Docs` folder.

---

## License

This project is licensed under the MIT License.

---

## About Me

I'm Adarsh, an Electronics and Computer Science Engineering graduate interested in Data Analytics, Business Intelligence, and Data Engineering.

I enjoy working with data, exploring patterns, solving analytical problems, and transforming raw data into meaningful insights.

I'm continuously learning and building hands-on projects to strengthen my technical skills and develop practical experience.
