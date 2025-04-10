This document describes the installation procedures for the Trino service. The following topics are covered in this chapter:

* [Prerequisites](#prerequisites)
  * [Common](#common) 
  * [Openshift](#openshift)
* [Best Practices and Recommendations](#best-practices-and-recommendations)
    * [Hardware Requirements](#hardware-requirements)
        * [Small](#small)
        * [Medium](#medium)
        * [Large](#large)
* [Parameters](#parameters)
  * [Enabling Password Authentication](#enabling-password-authentication)
  * [HTTPS/TLS for Trino](#httpstls-for-trino)
    * [Enable HTTPS/TLS for Trino Server](#enable-httpstls-for-trino-server)
    * [Secure Connections from Trino](#secure-connections-from-trino)
      * [Adding CA Certificates to Trino's Default Java Truststore](#adding-ca-certificates-to-trinos-default-java-truststore)
      * [Configure Trino Connectors To Use TLS/SSL](#configure-trino-connectors-to-use-tlsssl)
        * [PostgreSQL](#postgresql)
        * [Hive Metastore](#hive-metastore)
* [Installation](#installation)
    * [On-Prem](#on-prem)
        * [Manual Deployment](#manual-deployment) 
        * [Non-HA Scheme](#non-ha-scheme)
        * [HA Scheme](#ha-scheme)
* [Upgrade](#upgrade)
* [Rollback](#rollback)

# Prerequisites

The prerequisites are described in the following sections:

## Common

The common prerequisites are specified below.

* A namespace should be created.  

## Openshift

* If you are using the OpenShift cloud with restricted SCC, the Trino namespace must have specific annotations:

```bash
oc annotate --overwrite namespace trino openshift.io/sa.scc.uid-range="1000/1000"
oc annotate --overwrite namespace trino openshift.io/sa.scc.supplemental-groups="1000/1000"
```

# Best Practices and Recommendations

The best practices and recommendations are specified below.

## Hardware Requirements

The hardware requirements are specified below.

### Small

`Small` profile specifies the resources that are enough to start trino with the following parameters set:

server.config.query.maxMemory: "1GB"

server.config.query.maxMemoryPerNode: "512M"

server.config.memory.heapHeadroomPerNode: "512M"

coordinator.jvm.maxHeapSize: "819M"

coordinator.jvm.gcMethod.g1.heapRegionSize: "32M"

coordinator.config.query.maxMemoryPerNode: "512M"

worker.jvm.maxHeapSize: "1129M"

worker.jvm.gcMethod.g1.heapRegionSize: "32M"

worker.config.query.maxMemoryPerNode: "512M"

The profile resources are specified below:

|  Container  | CPU Limit | Memory Limit | Nomber of Containers |
|:-----------:|:---------:|:------------:|:--------------------:|
| Coordinator |   500m    |      1G      |          1           |
|   Worker    |   500m    |      1.5G    |          1           |

**Note**: The above resources are required for starting, not for working under load. For production, the resources should be increased.

### Medium

`Medium` profile specifies the approximate resources that are enough to run trino for dev purposes with the following parameters set to default values:

server.config.query.maxMemory: "2GB"

server.config.query.maxMemoryPerNode: "1GB"

server.config.memory.heapHeadroomPerNode: "1GB"

coordinator.jvm.maxHeapSize: "2457M"

coordinator.jvm.gcMethod.g1.heapRegionSize: "32M"

coordinator.config.query.maxMemoryPerNode: "1GB"

worker.jvm.maxHeapSize: "3276M"

worker.jvm.gcMethod.g1.heapRegionSize: "32M"

worker.config.query.maxMemoryPerNode: "1GB"

The profile resources are specified below:

|  Container  | CPU Limit | Memory Limit | Nomber of Containers |
|:-----------:|:---------:|:------------:|:--------------------:|
| Coordinator |     1     |      3G      |          1           |
|   Worker    |     1     |      4G      |          2           |

**Note**: The above resources are enough for development purposes, not for working under production load. For production, the resources should be increased.
<!-- #GFCFilterMarkerStart# -->

### Large

`Large` profile specifies the approximate resources that are enough to run trino for prod purposes with the following parameters set to default values:

server.config.query.maxMemory: "4GB"

server.config.query.maxMemoryPerNode: "2GB"

server.config.memory.heapHeadroomPerNode: "1GB"

coordinator.jvm.maxHeapSize: "4915M"

coordinator.jvm.gcMethod.g1.heapRegionSize: "64M"

coordinator.config.query.maxMemoryPerNode: "2GB"

worker.jvm.maxHeapSize: "6553M"

worker.jvm.gcMethod.g1.heapRegionSize: "64M"

worker.config.query.maxMemoryPerNode: "2GB"

The profile resources are specified below:

|  Container  | CPU Limit | Memory Limit | Nomber of Containers |
|:-----------:|:---------:|:------------:|:--------------------:|
| Coordinator |     2     |      6G      |          1           |
|   Worker    |     2     |      8G      |          3           |

<!-- #GFCFilterMarkerEnd# -->
# Parameters

This chart is based on community chart: https://github.com/trinodb/charts with a few minor changes.
The following table lists the configurable parameters of the Trino chart and their default values.

| Parameter                                           | Description                                                                                                                                                                                                                                                                                                                                                                                                      | Default                                              |
|-----------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------|
| `image.repository`                                  | The image repository.                                                                                                                                                                                                                                                                                                                                                                                            | `"trinodb/trino"` |
| `image.pullPolicy`                                  | The image pull policy.                                                                                                                                                                                                                                                                                                                                                                                           | `"IfNotPresent"`                                     |
| `image.tag`                                         | This overrides the image tag which is the Trino version by default.                                                                                                                                                                                                                                                                                                                                              | `"392"`                                              |
| `imagePullSecrets`                                  | An optional list of references to secrets in the same namespace to use for pulling any of the images used by this PodSpec.                                                                                                                                                                                                                                                                                       | `[{"name": "registry-credentials"}]`                 |
| `server.workers`                                    | The number of workers to run.                                                                                                                                                                                                                                                                                                                                                                                    | `2`                                                  |
| `server.node.environment`                           | The name of the environment. All Trino nodes in a cluster must have the same environment name. The name must start with a lowercase alphanumeric character and only contain lowercase alphanumeric or underscore (_) characters.                                                                                                                                                                                 | `"production"`                                       |
| `server.node.dataDir`                               | The location (filesystem path) of the data directory. Trino stores logs and other data here.                                                                                                                                                                                                                                                                                                                     | `"/data/trino"`                                      |
| `server.node.pluginDir`                             | The location (filesystem path) of the directory, where Trino plugins are located.                                                                                                                                                                                                                                                                                                                                | `"/usr/lib/trino/plugin"`                            |
| `server.log.trino.level`                            | It sets the Trino logs' level.                                                                                                                                                                                                                                                                                                                                                                                   | `"INFO"`                                             |
| `server.config.path`                                | The directory where coordinators' and workers' configurations are mounted.                                                                                                                                                                                                                                                                                                                                       | `"/etc/trino"`                                       |
| `server.config.authenticationType`                  | It specifies the authentication type for the Trino HTTP server: PASSWORD, OAUTH2, KERBEROS, CERTIFICATE, JWT, HEADER. Currently, only PASSWORD is supported.                                                                                                                                                                                                                                                     | `""`                                                 |
| `server.config.query.maxMemory`                     | The maximum amount of user memory a query can use across the entire cluster. User memory is allocated during an execution for things that are directly attributable to, or controllable by, a user query. For example, memory used by hash tables built during an execution, memory used during sorting, and so on. When the user memory allocation of a query across all workers hits this limit, it is killed. | `"2GB"`                                              |
| `server.config.query.maxMemoryPerNode`              | The maximum amount of user memory a query can use on a worker. User memory is allocated during an execution for things that are directly attributable to, or controllable by, a user query. For example, memory used by hash tables built during an execution, memory used during sorting, and so on. When the user memory allocation of a query on any worker hits this limit, it is killed.                    | `"1GB"`                                              |
| `server.config.memory.heapHeadroomPerNode`          | The amount of memory set aside as headroom/buffer in the JVM heap for allocations that are not tracked by Trino.                                                                                                                                                                                                                                                                                                 | `"1GB"`                                              |
| `server.exchangeManager`                       |                Mandatory [exchange manager configuration](https://trino.io/docs/current/admin/fault-tolerant-execution.html#id1). Used to set the name and location(s) of the spooling storage destination. To enable fault-tolerant execution, set the `retry-policy` property in `additionalConfigProperties`. Additional exchange manager configurations can be added to `additionalExchangeManagerProperties`.                                                                                                                                                                                                                                             | `{}`                                       |
| `server.workerExtraConfig`                          | The additional configurations to be added to the `config.properties` file of the workers.                                                                                                                                                                                                                                                                                                                        | `""`                                                 |
| `server.coordinatorExtraConfig`                     | The additional configurations to be added to the `config.properties` file of the coordinator.                                                                                                                                                                                                                                                                                                                    | `""`                                                 |
| `auth.passwordAuth`                                 | The username and password for authentication type PASSWORD.                                                                                                                                                                                                                                                                                                                                                      | `""`                                                 |
| `server.autoscaling.enabled`                        | It enables autoscaling for worker pods.                                                                                                                                                                                                                                                                                                                                                                          | `false`                                              |
| `server.autoscaling.maxReplicas`                    | It specifies the maximum number of worker pods when autoscaling is enabled.                                                                                                                                                                                                                                                                                                                                      | `5`                                                  |
| `server.autoscaling.targetCPUUtilizationPercentage` | It specifies the target CPU utilization percentage when autoscaling is enabled.                                                                                                                                                                                                                                                                                                                                  | `50`                                                 |
| `server.autoscaling.targetMemoryUtilizationPercentage` | It specifies the target memory utilization percentage when autoscaling is enabled.                                                                                                                                                                                                                                                                                                                                  | `80`                                                 |
| `accessControl`                                     | The system-level access control configuration.                                                                                                                                                                                                                                                                                                                                                                   | `{}`                                                 |
| `accessControl.type`                                | It should be `configmap` for system-level access control.                                                                                                                                                                                                                                                                                                                                                        | `configmap`                                          |
| `accessControl.refreshPeriod`                       | An optional property to refresh the properties without requiring a Trino restart. By default, when a change is made to the JSON rules file, Trino must be restarted to load the changes.                                                                                                                                                                                                                         | `60s`                                                |
| `accessControl.configFile`                          | The name of the configuration file that contains access control rules.                                                                                                                                                                                                                                                                                                                                           | `rules.json`                                         |
| `accessControl.rules`                               | The file with access control rules. An example of configuration can be found under this table.                                                                                                                                                                                                                                                                                                                   |                                                      |
| `additionalNodeProperties`                          | The additional configurations to be added to the `node.properties` file of the coordinator and workers.                                                                                                                                                                                                                                                                                                          | `{}`                                                 |
| `additionalConfigProperties`                        | The additional configurations to be added to the `config.properties` file of the coordinator and workers.                                                                                                                                                                                                                                                                                                        | `{}`                                                 |
| `additionalLogProperties`                           | The additional configurations to be added to the `log.properties` file of the coordinator and workers.                                                                                                                                                                                                                                                                                                           | `{}`                                                 |
| `additionalExchangeManagerProperties`               | The additional configurations to be added to the `exchange-manager.properties` file of the coordinator and workers.                                                                                                                                                                                                                                                                                              | `{}`                                                 |
| `eventListenerProperties`                           | The additional configurations to be added to the `event-listener.properties` file of the coordinator and workers.                                                                                                                                                                                                                                                                                                | `{}`                                                 |
| `catalogs`                                | The list of data source connection configuration.                                                                                                                                                                                                                                                                                                                                                                | `{"tpcds":"connector.name=tpcds\ntpcds.splits-per-node=4\n","tpch":"connector.name=tpch\ntpch.splits-per-node=4\n"}`                                                 |
| `additionalCatalogs`                                | Deprecated, use `catalogs` instead.                                                                                                                                                                                                                                                                                                                                                                | `{}`                                                 |
| `env`                                               | An array of environment variables for coordinator and workers.                                                                                                                                                                                                                                                                                                                                                   | `[]`                                                 |
| `initContainers.worker`                             | The init container configuration in YAML format for workers.                                                                                                                                                                                                                                                                                                                                                     | `{}`                                                 |
| `initContainers.coordinator`                        | The init container configuration in YAML format for the coordinator.                                                                                                                                                                                                                                                                                                                                             | `{}`                                                 |
| `securityContext`                         | All processes in coordinator and worker containers that run with the specified user or group.                                                                                                                                                                                                                                                                                                                             | `{"runAsGroup":1000,"runAsUser":1000}`                                               |
| `service.type`                                      | The type of Kubernetes service.                                                                                                                                                                                                                                                                                                                                                                                  | `"ClusterIP"`                                        |
| `service.port`                                      | It specifies the Trino HTTP server port.                                                                                                                                                                                                                                                                                                                                                                         | `8080`                                               |
| `auth.passwordAuth`                                 | It sets the username and password in the format "username:encrypted-password-with-htpasswd", when `server.config.authenticationType` is PASSWORD.                                                                                                                                                                                                                                                                | `{}`                                                 |
| `serviceAccount.create`                             | It specifies whether a service account should be created for Trino.                                                                                                                                                                                                                                                                                                                                              | `false`                                              |
| `serviceAccount.name`                               | The Trino service account name to use. If not set and create is true, a name is generated using the fullname template.                                                                                                                                                                                                                                                                                           | `""`                                                 |
| `serviceAccount.annotations`                        | The annotations to be added to the service account.                                                                                                                                                                                                                                                                                                                                                              | `{}`                                                 |
| `secretMounts`                                      | An array of Kubernetes secrets to mount into coordinator and worker pods. Each element should have the name, secretName, and path (where to mount) properties.                                                                                                                                                                                                                                                   | `[]`                                                 |
| `coordinator.deployment.progressDeadlineSeconds`                       |   The maximum time in seconds for a deployment to make progress before it is considered failed. The deployment controller continues to process failed deployments and a condition with a ProgressDeadlineExceeded reason is surfaced in the deployment status.                                                                                                          | `600`                                            |
| `coordinator.deployment.revisionHistoryLimit`                       |     The number of old ReplicaSets to retain to allow rollback.                                                                                                         | `10`                                            |
| `coordinator.deployment.strategy`                       |     The deployment strategy to use to replace existing pods with new ones.                                                                                                         | `{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"}`                                            |
| `coordinator.jvm.maxHeapSize`                       | The coordinator's JVM maximum heap size. Typically, the value representing 70 to 85 percent of the total available memory is recommended.                                                                                                                                                                                                                                                                        | `"1638M"`                                            |
| `coordinator.jvm.gcMethod.type`                     | The JVM GC type for the coordinator. It should be set as a JVM command line option.                                                                                                                                                                                                                                                                                                                              | `"UseG1GC"`                                          |
| `coordinator.jvm.gcMethod.g1.heapRegionSize`        | It sets the JVM GC1 heap region size for the coordinator.                                                                                                                                                                                                                                                                                                                                                        | `"32M"`                                              |
| `coordinator.additionalJVMConfig`                   | The additional configurations to be added to the `jvm.config` file of the coordinator.                                                                                                                                                                                                                                                                                                                           | `{}`                                                 |
| `coordinator.resources`                             | It sets the coordinator's resources.                                                                                                                                                                                                                                                                                                                                                                             | `{}`                                                 |
| `coordinator.livenessProbe`                         | It overrides the coordinator's livenessProbe.                                                                                                                                                                                                                                                                                                                                                                    | `{}`                                                 |
| `coordinator.readinessProbe`                        | It overrides the coordinator's readinessProbe.                                                                                                                                                                                                                                                                                                                                                                   | `{}`                                                 |
| `coordinator.nodeSelector`                          | It sets nodeselector for the coordinator.                                                                                                                                                                                                                                                                                                                                                                        | `{}`                                                 |
| `coordinator.tolerations`                           | It sets tolerations for the coordinator.                                                                                                                                                                                                                                                                                                                                                                         | `[]`                                                 |
| `coordinator.affinity`                              | It sets the affinity for the coordinator.                                                                                                                                                                                                                                                                                                                                                                        | `{}`                                                 |
| `coordinator.priorityClassName`                     | Priority class name for the coordinator.                                                                                                                                                                                                                                                                                                                                                                         | `{}`                                                 |
| `worker.deployment.progressDeadlineSeconds`                       |   The maximum time in seconds for a deployment to make progress before it is considered failed. The deployment controller continues to process failed deployments and a condition with a ProgressDeadlineExceeded reason is surfaced in the deployment status.                                                                                                          | `600`                                            |
| `worker.deployment.revisionHistoryLimit`                       |     The number of old ReplicaSets to retain to allow rollback.                                                                                                         | `10`                                            |
| `worker.deployment.strategy`                       |     The deployment strategy to use to replace existing pods with new ones.                                                                                                         | `{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"}`                                            |
| `worker.jvm.maxHeapSize`                            | The worker's JVM maximum heap size. Typically, values representing 70 to 85 percent of the total available memory is recommended.                                                                                                                                                                                                                                                                                | `"2457M"`                                            |
| `worker.jvm.gcMethod.type`                          | The JVM GC type for workers. It should be set as a JVM command line option.                                                                                                                                                                                                                                                                                                                                      | `"UseG1GC"`                                          |
| `worker.jvm.gcMethod.g1.heapRegionSize`             | It sets the JVM GC1 heap region size for workers.                                                                                                                                                                                                                                                                                                                                                                | `"32M"`                                              |
| `worker.additionalJVMConfig`                        | The additional configurations to be added to the `jvm.config` file of workers.                                                                                                                                                                                                                                                                                                                                   | `{}`                                                 |
| `worker.resources`                                  | It sets the worker's resources.                                                                                                                                                                                                                                                                                                                                                                                  | `{}`                                                 |
| `worker.livenessProbe`                              | It overrides the worker's livenessProbe.                                                                                                                                                                                                                                                                                                                                                                         | `{}`                                                 |
| `worker.readinessProbe`                             | It overrides the worker's readinessProbe.                                                                                                                                                                                                                                                                                                                                                                        | `{}`                                                 |
| `worker.nodeSelector`                               | It sets nodeselector for workers.                                                                                                                                                                                                                                                                                                                                                                                | `{}`                                                 |
| `worker.tolerations`                                | It sets tolerations for workers.                                                                                                                                                                                                                                                                                                                                                                                 | `[]`                                                 |
| `worker.affinity`                                   | It sets the affinity for workers.                                                                                                                                                                                                                                                                                                                                                                                | `{}`                                                 |
| `worker.priorityClassName`                          | Priority class name for workers.                                                                                                                                                                                                                                                                                                                                                                                 | `{}`                                                 |
| `worker.gracefulShutdown`                          |   Configure [graceful shutdown](https://trino.io/docs/current/admin/graceful-shutdown.html) in order to ensure that workers terminate without affecting running queries, given a sufficient grace period. When enabled, the value of `worker.terminationGracePeriodSeconds` must be at least two times greater than the configured `gracePeriodSeconds`. Enabling `worker.gracefulShutdown` conflicts with `worker.lifecycle`. When a custom `worker.lifecycle` configuration needs to be used, graceful shutdown must be configured manually.                                                                                                                                                                                                                                                                                                                                                                                 | `{"enabled":false,"gracePeriodSeconds":120}`                                                 |
| `kafka.mountPath`                                   | The path to mount custom Kafka table descriptions.                                                                                                                                                                                                                                                                                                                                                               | `"/etc/trino/schemas"`                               |
| `kafka.tableDescriptions`                           | The custom Kafka table descriptions that are mounted in `kafka.mountPath`.                                                                                                                                                                                                                                                                                                                                       | `{}`                                                 |
| `ingress.enabled`                                   | If Trino ingress should be deployed.                                                                                                                                                                                                                                                                                                                                                                             | `false`                                              |
| `ingress.className`                                 | Ingress className.                                                                                                                                                                                                                                                                                                                                                                                               | `""`                                                 |
| `ingress.annotations`                               | Ingress annotations.                                                                                                                                                                                                                                                                                                                                                                                             | `{}`                                                 |
| `ingress.hosts`                                     | Ingress hosts configuration.                                                                                                                                                                                                                                                                                                                                                                                     | `[]`                                                 |
| `ingress.tls`                                       | Ingress tls configuration.                                                                                                                                                                                                                                                                                                                                                                                       | `[]`                                                 |
| `networkPolicy.enabled`                                    |   Set to true to enable Trino pod protection with a [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). By default, the NetworkPolicy will only allow Trino pods to communicate with each other.                                                                                                                                                                                                                                                                                                                                                                                                                 |`false`|
| `networkPolicy.ingress`                                    |    Additional ingress rules to apply to the Trino pods.                                                                                                                                                                                                                                                                                                                                                                                                                 |`[]`|
| `networkPolicy.egress`                                    |      Egress rules to apply to the Trino pods.                                                                                                                                                                                                                                                                                                                                                                                                                 |`[]`|
| `resourceGroups`                                    |                                                                                                                                                                                                                                                                                                                                                                                                                  |`{}`|

An example of `accessControl` configuration is as follows:

```yaml
accessControl:
  type: configmap
  refreshPeriod: 60s
  configFile: "rules.json"
  rules:
    rules.json: |-
      {
        "catalogs": [
          {
            "user": "admin",
            "catalog": "(mysql|system)",
            "allow": "all"
          },
          {
            "group": "finance|human_resources",
            "catalog": "postgres",
            "allow": true
          },
          {
            "catalog": "hive",
            "allow": "all"
          },
          {
            "user": "alice",
            "catalog": "postgresql",
            "allow": "read-only"
          },
          {
            "catalog": "system",
            "allow": "none"
          }
        ],
        "schemas": [
          {
            "user": "admin",
            "schema": ".*",
            "owner": true
          },
          {
            "user": "guest",
            "owner": false
          },
          {
            "catalog": "default",
            "schema": "default",
            "owner": true
          }
        ]
      }
```

Examples of ingress configuration is as follows:

```yaml
ingress:
  enabled: true
  hosts:
    - host: trino.apps.ingress.test.com
      paths:
        - path: /
          pathType: ImplementationSpecific
```

## Enabling Password Authentication

**Note**: In previous releases, configuring trino authentication was done using nodeport service. Now nodeport service is deprecated and not recommended, please use ingress instead.

**Note**: In supported configurations, password authentication only works for ingresses/routes with enabled TLS. It does not matter if TLS for ingress/route is enabled globally by the cloud or locally by ingress configuration - Trino checks that ingress/route terminates TLS traffic.

1. Enable password authentication.

Trino uses one of the authentication types called `Password file`.

1.1 Creating a password file.

Create an empty password file to get started.

```bash
touch password.db
```

Add or update the password for the user `test`.

```bash
htpasswd -B -C 10 password.db test
```

1.2 Example configuration is as follows.

```yaml
server:
  config:
    authenticationType: PASSWORD
  coordinatorExtraConfig: |
    internal-communication.shared-secret='trino-password-authentication'
    http-server.process-forwarded=true
  workerExtraConfig: internal-communication.shared-secret='trino-password-authentication'
auth: |
  passwordAuth: test: cat password.db
```

Example `passwordAuth` for "qwerty123" password:

```yaml
test:$2y$10$5hiVJt3Ru/0dx8cMya7Cr.rd.2RV02rLj0ybnw8xXhRBljjpbFw/m
```

You can create multiple users to work in Trino.

For example:

```yaml
auth:
  passwordAuth: |
    username1:password1
    username2:password2
```

**Setting Trino Client to use `passwordAuth`**:

For more information, refer to the [Trino Client](../../docs/public/user-guide.md#trino-client) section in the User Guide.

For more information, refer to the [DBeaver passwordauth](../../docs/public/user-guide.md#dbeaver-passwordauth) section in the User Guide.

## HTTPS/TLS for Trino

You can use two options to enable HTTPS/TLS - create certificates manually or enable certificates generation.  
Details are described in the below sections.

En example of TLS configuration that enables TLS on Trino ingress and adds CA certificate to secure connections from Trino:
```yaml
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: common-cluster-issuer
  tls:
    - hosts:
        - trino.apps.ingress.test.com
      secretName: tls-ingress-cert
  hosts:
    - host: trino.apps.ingress.test.com
      paths:
        - path: /
          pathType: ImplementationSpecific

tls:
  enabled: true
  generateCerts:
    enabled: true
    clusterIssuerName: common-cluster-issuer
```

If you want to customize the default setting, use the detailed configuration:

```yaml
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: common-cluster-issuer
  tls:
    - hosts:
        - trino.apps.ingress.test.com
      secretName: tls-ingress-cert
  hosts:
    - host: trino.apps.ingress.test.com
      paths:
        - path: /
          pathType: ImplementationSpecific
          
tls:
   enabled: true
   generateCerts:
      enabled: true
      secretName: trino-cm-tls-cert
      secretMounts:
         - mountPath: /home/trino/trustcerts/ca.crt
           subPath: ca.crt
      duration: 365
      subjectAlternativeName:
         additionalDnsNames: [ ]
         additionalIpAddresses: [ ]
      clusterIssuerName: common-cluster-issuer
```

### Enable HTTPS/TLS for Trino Server

It is possible to enable TLS on trino web UI directly inside kubernetes. For this, trino server needs TLS key and certificate. TLS key and certificate can be requested from cert-manager using `certManagerInegration.enabled` parameter. By default, it will create secret `trino-cm-tls-cert` with TLS certificate, TLS key and CA certificate. It is necessary to specify HTTPS scheme for webserver liveness, readiness and startup probes. If using kubernetes with NGINX ingress controller, it is possible to pass annotations for ingress controller to work with TLS backend, for example:
```yaml
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: common-cluster-issuer
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/proxy-ssl-name: trino.trino-namespace
    nginx.ingress.kubernetes.io/proxy-ssl-secret: trino-namespace/trino-cm-tls-cert
    nginx.ingress.kubernetes.io/proxy-ssl-verify: 'on'

  tls:
    - hosts:
        - trino.apps.ingress.test.com
      secretName: tls-ingress-cert
  hosts:
    - host: trino.apps.ingress.test.com
      paths:
        - path: /
          pathType: ImplementationSpecific
```
### Re-encrypt Route In Openshift Without NGINX Ingress Controller

Automatic re-encrypt Route creation is not supported out of box, need to perform the following steps:

1. Disable Ingress in deployment parameters: `ingress.web.enabled: false`.

   Deploy with enabled web Ingress leads to incorrect Ingress and Route configuration.

2. Create Route manually. You can use the following template as an example:

   ```yaml
   kind: Route
   apiVersion: route.openshift.io/v1
   metadata:
     annotations:
       route.openshift.io/termination: reencrypt
     name: <specify-uniq-route-name>
     namespace: <specify-namespace-where-trino-is-installed>
   spec:
     host: <specify-your-target-host-here>
     to:
       kind: Service
       name: <trino-service-name-for-example-trino>
       weight: 100
     port:
       targetPort: http
     tls:
       termination: reencrypt
       destinationCACertificate: <place-CA-certificate-here-from-trino-TLS-secret>
       insecureEdgeTerminationPolicy: Redirect
   ```

**Note**: If you can't access the webserver host after Route creation because of "too many redirects" error, then one of the possible root
causes is there is HTTP traffic between balancers and the cluster. To resolve that issue it's necessary to add the Route name to
the exception list at the balancers.

**Note** It might be possible to create the route in openshift automatically using annotations like `route.openshift.io/destination-ca-certificate-secret` and `route.openshift.io/termination: "reencrypt"` but this approach was not tested.

### Enable HTTPS/TLS for Trino Ingress-Service communication

To enable HTTPS/TLS communication between ingress and service populate ingress annotations as below:.
```yaml
server:
  config:
    htps:
      enabled: true
```

### Secure Connections from Trino

In order to secure the connections from Trino using TLS/SSL:

- Depending on the certificate used by a service that Trino will be connecting, an appropriate CA certificate needs to be imported to Java default truststore.
- Connectors in Trino catalog should be configured to use TLS/SSL.

#### Adding CA Certificates to Trino's Default Java Truststore

There are three options for adding certificates to Trino.

**Note**: The certificate should be mounted to `/home/trino/trustcerts`. All certificates from that directory are added to Java default truststore - cacerts.

1. Enable the certificate generation to use cert-manager certificates.

```yaml
tls:
  enabled: true
  generateCerts:
    enabled: true
    secretName: trino-cm-tls-cert
    secretMounts:                                
      - mountPath: /home/trino/trustcerts/ca.crt <---------- certificate should be mounted to "/home/trino/trustcerts"
        subPath: ca.crt
    duration: 365
    subjectAlternativeName:
      additionalDnsNames: [ ]
      additionalIpAddresses: [ ]
    clusterIssuerName: common-cluster-issuer     <--------- issuer should be the same as for the connecting service's certificate
```

2. Add certificates using `extraSecrets` deployment parameter. In this case, the added secret should be mounted into the coordinator and the workers pod.  
   Mounting details are set using the `additionalVolumes` and `additionalVolumeMounts` parameters. The Certificates should be mounted to "/home/trino/trustcerts".
```yaml
extraSecrets:
   mysslcert: # secret name
      stringData: |
         mysslcert.crt: |
           -----BEGIN CERTIFICATE-----
           cert content goes here
           -----END CERTIFICATE-----
coordinator:
  additionalVolumes:
    - name: tls-custom-cert
      secret:
        secretName: mysslcert
  additionalVolumeMounts:
    - name: tls-custom-cert
      mountPath: /home/trino/trustcerts/mysslcert.crt
      subPath: mysslcert.crt
      readOnly: true
worker:
  additionalVolumes:
    - name: tls-custom-cert
      secret:
        secretName: mysslcert
  additionalVolumeMounts:
    - name: tls-custom-cert
      mountPath: /home/trino/trustcerts/mysslcert.crt
      subPath: mysslcert.crt
      readOnly: true
```
3. Add the existing secret to truststore. In this case, only `additionalVolumes` and `additionalVolumeMounts` parameters need to be configured to mount the secret to coordinator and worker pods.
```yaml
coordinator:
  additionalVolumes:
    - name: defaultcert
      secret:
        secretName: defaultsslcertificate
  additionalVolumeMounts:
    - name: defaultcert
      mountPath: /home/trino/trustcerts/ca-bundle.crt
      subPath: ca-bundle.crt
      readOnly: true
worker:
   additionalVolumes:
      - name: defaultcert
        secret:
           secretName: defaultsslcertificate
   additionalVolumeMounts:
      - name: defaultcert
        mountPath: /home/trino/trustcerts/ca-bundle.crt
        subPath: ca-bundle.crt
        readOnly: true
```

#### Configure Trino Connectors To Use TLS/SSL

The below sub-sections provide information on configuring Trino connectors to use TLS/SSL.

##### PostgreSQL

Add the following properties to PG connection string `ssl=true&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory`.  
You can find the other configuration details in the _PG Documentation_ at [https://jdbc.postgresql.org/documentation/ssl/#configuring-the-client](https://jdbc.postgresql.org/documentation/ssl/#configuring-the-client).

```yaml
catalogs:
  postgres: |
    connector.name=postgresql
    connection-url=jdbc:postgresql://pg-patroni.postgres-tls:5432/db_to_connect?ssl=true&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory
    connection-user=postgres
    connection-password=password
```

To ignore certificate validation, `sslfactory` should be set to `org.postgresql.ssl.NonValidatingFactory` in the connection string.

##### Hive Metastore

To secure connection to Hive Metastore `hive.metastore.thrift.client.*` properties as shown in the example below should be added to Hive connector configuration.

```yaml
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
    
    <-----Secure connection to Hive Metastore-------->
    hive.metastore.thrift.client.ssl.enabled=true
    hive.metastore.thrift.client.ssl.key=/usr/lib/jvm/temurin/jdk-24+36/lib/security/cacerts
    hive.metastore.thrift.client.ssl.key-password=changeit
    hive.metastore.thrift.client.ssl.trust-certificate=/usr/lib/jvm/temurin/jdk-24+36/lib/security/cacerts
    hive.metastore.thrift.client.ssl.trust-certificate-password=changeit
```

To enable secure connection to S3 storage, `hive.s3.ssl.enabled=true` should be set to true.

To ignore certificate validation for S3, the following properties should be added:
```yaml
coordinator:
# disable S3 cert validation
  additionalJVMConfig:
    - -Dcom.amazonaws.sdk.disableCertChecking

worker:
   # disable S3 cert validation
   additionalJVMConfig:
      - -Dcom.amazonaws.sdk.disableCertChecking
```

There is no option to ignore the certificate validation for Hive Metastore.

# Installation

The installation process is specified below.

## Before You Begin

Installation [prerequisites](#prerequisites) should be fulfilled to prepare for the installation.

## On-Prem

### Manual Deployment

The open source Helm chart is used to deploy Trino.

1. Navigate to the desired release tag and download the `<repo_root>/chart/helm/trino` directory.
   
1. Edit the parameters in the **values.yaml** file. The configuration parameter details are described in the [Trino Configuration](/docs/public/installation.md#parameters) section.

1. Install the chart to the K8s namespace created in the [Prerequisites](#prerequisites) section.

   ```
   helm install <helm release name> <path to chart directory> --values <path to values.yaml file> --namespace <namespace to install Trino> --debug
   #Example
   helm install trino . --debug
   ```

### Non-HA Scheme

Trino is deployed in the non-HA scheme by default.

### HA Scheme

Not supported.

# Upgrade

The process of the Trino service upgrade is usual and does not contain any specific steps.

# Rollback

Trino service does not support rollback. In order to install an older version, the following steps should be performed:

1. Clear the Trino service's namespace by recreating it.

```
kubectl delete namespace <trino_namespace>

kubectl create namespace <trino_namespace>
```

2. Run installation with the older version.
