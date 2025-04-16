This guide describes how Trino can be used.

The following sections are described in this chapter:

* [Trino Connectors](#trino-connectors)
  * [PostgresSQL](#postgressql)
  * [Hive](#hive)
  * [Redis](#redis)
  * [Cassandra](#cassandra)
* [Trino Client](#trino-client)
  * [DBeaver](#dbeaver)
  * [DBeaver passwordauth](#dbeaver-passwordauth)

## Trino Connectors

Trino can execute SQL queries against several data storages. Trino connectors should be configured for each of them.  
The full list of possible connectors can be found at [https://trino.io/docs/current/connector.html](https://trino.io/docs/current/connector.html).

The example connectors in CMBD config are specified in the below sub-sections.

### PostgresSQL

The following is an example of the PostgreSQL connector configuration that should be added to Trino's deployment parameters:

```yaml
catalogs:
 postgresql: |
  connector.name=postgresql
  connection-url=jdbc:postgresql://example.net:5432/database
  connection-user=user_name
  connection-password=password
```

### Hive

The following is an example of Hive that uses S3 storage, connector configuration that should be added to Trino's deployment parameters:

```yaml
catalogs:
  hive: |
    connector.name=hive
    hive.metastore.uri={{ include "hive.metastore.uri" . }}
    hive.max-partitions-per-scan=1000000
    hive.storage-format=ORC
    hive.non-managed-table-writes-enabled=true
    fs.native-s3.enabled=true
    s3.endpoint={{ include "s3.endpoint" . }}
    s3.region={{ .Values.s3.region }}
    s3.aws-access-key={{ include "s3.accesskey" . }}
    s3.aws-secret-key={{ include "s3.secretkey" . }}
    s3.path-style-access=true
    s3.max-connections=100
```

Use the `USE` statement to specify the Hive catalog and scheme to submit queries in DBeaver:

```postgresql
USE hive.default;
SHOW tables;
CREATE TABLE table_test(id varchar, name varchar) with (format = 'parquet', external_location = 's3a://hive/warehouse/table_test');
INSERT INTO table_test VALUES ('1', 'San Francisco');
SELECT * FROM table_test;
```

### Redis

The following is an example of the Redis connector configuration that should be added to Trino's deployment parameters:

```yaml
catalogs:
  redis: |
    connector.name=redis
    redis.table-names: redis
    redis.nodes: redis.redis
    redis.default-schema: default
    redis.password: redis
    redis.database-index: 1
    redis.table-description-dir: /dbadditionalconfigs/test.json
```

### Cassandra

The following is an example of the Cassandra connector configuration that should be added to Trino's deployment parameters:

```yaml
catalogs:
  cassandra: |
    connector.name=cassandra
    cassandra.contact-points=cassandra.cassandra
    cassandra.native-protocol-port=9042
    cassandra.security=PASSWORD
    cassandra.username=admin
    cassandra.password=admin
    cassandra.load-policy.dc-aware.local-dc=dc1
    cassandra.load-policy.use-dc-aware=true
    cassandra.load-policy.dc-aware.allow-remote-dc-for-local=true
```

## Trino Client 

To send SQL queries to Trino, you should use a client.  

Trino Client to use `passwordAuth`:

**Warning**: There must be a Trino client in the pod.

To connect via Trino client, use the following command:

```bash
Use certificate for connect to trino
trino --server <your.ingress.address> --ssl --ssl-cert <path certificate> --user <username> --password

Use insecure mode for connect to trino
trino --server <your.ingress.address> --insecure --user <username> --password
```

### DBeaver

To use DBeaver as a Trino client, the following configuration should be done:

1. Download and install DBeaver.
2. Open DBeaver. 
3. Navigate to **File** > **New**.
4. Select **DBeaver** as a wizard > **Database Connection**.
5. Select **Trino** in the list of possible databases.
6. Enter the Trino connection parameters.
    * JDBC URL: <your.ingress.address>
    * Port: Navigate to K8s and open the Trino service. The port is specified at `spec.ports.nodePort`.
    * Username and password are specified during the deployment. By default, `admin` is the username and the password is blank.
      
![DBeaver Trino Connection](/docs/public/images/DBeaver-Trino-Connection.png)

### DBeaver passwordauth

To use the password authentication in Dbeaver, refer to the _Official Documentation_ at [https://techjogging.com/connect-dbeaver-presto-https-protocol.html](https://techjogging.com/connect-dbeaver-presto-https-protocol.html).
