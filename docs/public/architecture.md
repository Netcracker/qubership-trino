This document describes the architectural features of Trino. 

## Table of Contents

* [Overview](#overview)
* [Trino Components](#trino-components)
* [Supported Deployment Scheme](#supported-deployment-scheme)
    * [On-Prem](#on-prem)
        * [Non-HA Deployment Scheme](#non-ha-deployment-scheme)

## Overview

Trino is a distributed SQL query engine. Rather than relying on vertical scaling of the server running Trino, it is able to distribute all processing across a cluster of servers in a horizontal fashion. This means that you can add more nodes to gain more processing power.

Following are the Trino use cases:

* Centralized data access and analytics with query federation.
* High performance analytics of object storage with SQL.

## Trino Components

Trino installation includes one coordinator and any number of Trino workers.  

![alt text](/docs/public/images/trino_architecture.png "Trino Architecture")

The **Coordinator** is responsible for parsing, planning, and scheduling query execution across Trino workers.  
The coordinator node performs the following functions for each query:

* Handles communications with clients
* Parses and analyzes queries
* Creates a logical model of each query
* Plans and optimizes query processing
* Schedules query execution
* Tracks worker activity

**Worker** nodes are responsible for executing tasks assigned to them by the coordinator’s scheduler, including retrieving and processing data from data sources. 
They communicate not only with the coordinator and data sources, but also with each other directly.
Adding more Trino workers allows for more parallelism and faster query processing.

The configuration necessary to access a data source is called a Catalog. Each catalog is configured with the connector 
for a particular data source. A connector is called when a catalog that is configured to use the connector is used in a query. 
Data source connections are established based on the catalog configuration.

```yaml
catalogs:
 postgresql: |
  connector.name=postgresql
  connection-url=jdbc:postgresql://postgreshost/db_hive
  connection-user=hive_user
  connection-password=hive_password
```

**Clients** are used to submit queries to Trino.

# Supported Deployment Scheme

## On-Prem

### Non-HA Deployment Scheme

Currently, Trino supports only the non-HA deployment scheme. A Trino cluster consists of a coordinator and many workers. 
By default, there is one worker.

![alt text](/docs/public/images/trino_non_ha.png "Trino Non-HA Deployment")
