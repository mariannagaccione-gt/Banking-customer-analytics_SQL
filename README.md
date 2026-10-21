# Banking-customer-analytics_SQL

## Overview

This project was developed as the final assignment for the SQL module of a Master's program in Data Analytics.

The objective is to transform relational banking data into a denormalized customer-level dataset, with one row per customer and a set of numerical indicators suitable for further analysis and predictive modeling.

## Objectives

- Calculate customer age.
- Aggregate incoming and outgoing transactions across all accounts.
- Calculate the total number of accounts and the number of accounts by account type.
- Calculate transaction counts and amounts by direction and account type.
- Retain customers with no transactions or no accounts of a given type, using zero values for the relevant indicators.

## Tools

- MySQL
- SQL views and aggregations
- Joins and conditional aggregation
- Table creation and data insertion

## Deliverables

- A documented SQL script to create and populate the customer-level analytical table.
## Prerequisites
Before running the SQL script, ensure that the source database has been created and populated with the required tables and data. The database creation script is also available in this repository and must be executed first. Once the database is set up, you can run the main SQL script to generate the denormalized customer-level dataset.
