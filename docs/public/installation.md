This guide describes the installation procedures for the Trino service. 

The following topics are covered in this chapter:

* [Prerequisites](#prerequisites)
  * [Common](#common) 
  * [OpenShift](#openshift)
* [Best Practices and Recommendations](#best-practices-and-recommendations)
    * [Hardware Requirements](#hardware-requirements)
        * [Small](#small)
        * [Medium](#medium)
        * [Large](#large)
    * [Read Only Root Filesystem](#read-only-root-filesystem)    
* [Parameters](#parameters)
  * [Enabling Password Authentication](#enabling-password-authentication)
  * [HTTPS/TLS for Trino](#httpstls-for-trino)
    * [Enable HTTPS/TLS for Trino Server](#enable-httpstls-for-trino-server)
    * [Secure Connections from Trino](#secure-connections-from-trino)
      * [Adding CA Certificates to Trino's Default Java Truststore](#adding-ca-certificates-to-trinos-default-java-truststore)
      * [Configure Trino Connectors To Use TLS/SSL](#configure-trino-connectors-to-use-tlsssl)
        * [PostgreSQL](#postgresql)
        * [Hive Metastore](#hive-metastore)
  * [HTTPRoute for K8S Gateway API Support](#httproute-for-k8s-gateway-api-support)
  * [Redirection of Internal Filesystem Stored Logs to stdout](#redirection-of-internal-filesystem-stored-logs-to-stdout)
  * [Dynamic Catalogs (Experimental)](#dynamic-catalogs-experimental)      
  * [Using SeaweedFS with the Hive Connector](#using-seaweedfs-with-the-hive-connector)
* [Installation](#installation)
    * [On-Prem](#on-prem)
        * [Manual Deployment](#manual-deployment) 
        * [Non-HA Scheme](#non-ha-scheme)
        * [HA Scheme](#ha-scheme)
* [Upgrade](#upgrade)
* [Rollback](#rollback)

# Prerequisites

The prerequisites are described in the following sub-sections:

## Common

The common prerequisites are specified below.

* A namespace should be created.  

## OpenShift

If you are using the OpenShift cloud with restricted SCC, the Trino namespace must have specific annotations:

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

### Read Only Root Filesystem

To improve the security posture of the application, the deployment is configured with a read-only root filesystem. This prevents the container process from writing to any location on the disk except for specifically designated volumes.

The following settings are applied:
```
securityContext:
  readOnlyRootFilesystem: true
```  
Since the root filesystem is locked, we use emptyDir volumes to provide writable space for temporary operations and for certificates storage. Automated Volume Mounts so no need to manually configure additional storage. 

The following volumes are already provisioned in the deployment to handle standard application requirements:

 | Volume Name | Mount Path | Sub Path | Purpose | 
 |:-------------:|:---------:|:------------:|:-------------:|
 | common-space | /tmp | tmp-data | Provides a writable area for temporary files, and general OS-level buffers. |
 | common-space | /data/trino | trino-var | Stores the PID file (launcher.pid). |
 | java-cacerts-dir| /java-security | java-security | Used specifically for managing Java truststores and security certificates at runtime. |


#### Trino CLI History Configuration

By default, the Trino CLI attempts to write command history to the user's home directory, for example, /home/trino/.trino_history. In a read-only filesystem environment, this will cause the CLI to fail or throw errors upon execution.

To ensure the CLI remains functional, the TRINO_HISTORY_FILE environment variable is used to redirect the history file to the writable common-space volume mounted at /tmp.

Required Environment Variable: 
| Variable Name | Value | Purpose | 
|:--- |:--- |:--- | 
| TRINO_HISTORY_FILE | /tmp/.trino_history | Redirects CLI command history to a writable temporary volume. |

**Note**: This configuration is already pre-set in the values.yaml file and requires no manual intervention.

# Parameters

This chart is based on community chart: https://github.com/trinodb/charts with a few minor changes.
It also includes a values.schema.json file, a custom schema that defines the structure, types, and allowed fields for values.yaml, ensuring configurations are valid and consistent. This enables Helm to validate the inputs during linting and templating, helping prevent misconfigurations at deployment time.

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
| `server.workerExtraConfig`                          | The additional configurations to be added to the `config.properties` file of the workers. Default enables dynamic catalog management.                                                                                                                                                                                                                                                                             | `catalog.management=dynamic`                         |
| `server.coordinatorExtraConfig`                     | The additional configurations to be added to the `config.properties` file of the coordinator. Default enables dynamic catalog management and preserves `http-server.process-forwarded=IGNORE`.                                                                                                                                                                                                                    | see values.yaml                                      |
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
| `coordinator.deployment.strategy`                       |     The deployment strategy to use to replace the existing pods with new ones. Defaults to `Recreate` because the dynamic catalog PVC is `ReadWriteOnce` and cannot be mounted by two coordinator pods at the same time.                                                                                                         | `{"type":"Recreate"}`                                            |
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
| `GATEWAY_SYSTEM_TYPE`                             | The mode of Gateway applications must use during installation: `"legacy-ingress"`, `"gateway-api-default"`, or `"legacy-ingress, gateway-api-default"` for both. When `ingress.enabled`/`gateway.enabled` are `null`, the chart derives whether to create the Ingress and/or HTTPRoute from this value.                                                                                                                                                                              | `"legacy-ingress"`                                   |
| `GATEWAY_SYSTEM_NAME`                               | The name of the Gateway API Gateway controller, used as `spec.parentRefs.name` on HTTPRoute resources.                                                                                                                                                                                                                                                                                                           | `"default-external-gateway"`                         |
| `GATEWAY_SYSTEM_NAMESPACE`                          | The namespace of the Gateway API Gateway controller, used as `spec.parentRefs.namespace` on HTTPRoute resources.                                                                                                                                                                                                                                                                                                  | `"gateway-system"`                                   |
| `ingress.enabled`                                   | If Trino ingress should be deployed. `false` by default; set to `null` to derive it from `GATEWAY_SYSTEM_TYPE` containing `"legacy-ingress"`, or `true`/`false` to override.                                                                                                                                                                                                                                                                         | `false`                                              |
| `ingress.className`                                 | Ingress className.                                                                                                                                                                                                                                                                                                                                                                                               | `""`                                                 |
| `ingress.annotations`                               | Ingress annotations.                                                                                                                                                                                                                                                                                                                                                                                             | `{}`                                                 |
| `ingress.hosts`                                     | Ingress hosts configuration.                                                                                                                                                                                                                                                                                                                                                                                     | `[]`                                                 |
| `ingress.tls`                                       | Ingress tls configuration.                                                                                                                                                                                                                                                                                                                                                                                       | `[]`                                                 |
| `networkPolicy.enabled`                                    |   Set to true to enable Trino pod protection with a [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). By default, the NetworkPolicy will only allow Trino pods to communicate with each other.                                                                                                                                                                                                                                                                                                                                                                                                                 |`false`|
| `networkPolicy.ingress`                                    |    Additional ingress rules to apply to the Trino pods.                                                                                                                                                                                                                                                                                                                                                                                                                 |`[]`|
| `networkPolicy.egress`                                    |      Egress rules to apply to the Trino pods.                                                                                                                                                                                                                                                                                                                                                                                                                 |`[]`|
| `resourceGroups`                                    |                                                                                                                                                                                                                                                                                                                                                                                                                  |`{}`|
| `dynamicCatalogPVC.enabled`                         | Create a PersistentVolumeClaim for the coordinator's catalog directory. Enabled by default; the chart mounts it automatically and creates `catalog-store.properties`. Set to `false` to use static catalog management only. See [Dynamic Catalogs](#dynamic-catalogs).                                                                                                                                                                                  | `true`                                               |
| `dynamicCatalogPVC.storageClass`                    | StorageClass for the PVC (can be templated). Leave empty to use the cluster default.                                                                                                                                                                                                                                                                                                                                                | `""`                                                 |
| `dynamicCatalogPVC.accessMode`                      | Access mode for the PVC.                                                                                                                                                                                                                                                                                                                                                                                         | `"ReadWriteOnce"`                                    |
| `dynamicCatalogPVC.size`                            | Storage size for the PVC.                                                                                                                                                                                                                                                                                                                                                                                        | `"1Gi"`                                              |
| `dynamicCatalogPVC.existingClaim`                   | Name of an existing PVC to use instead of creating a new one.                                                                                                                                                                                                                                                                                                                                                    | `""`                                                 |

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

**Note**: In previous releases, configuring trino authentication was done using nodeport service. Now the nodeport service is deprecated and not recommended, please use ingress instead.

**Note**: In the supported configurations, password authentication only works for ingresses/routes with enabled TLS. It does not matter if TLS for ingress/route is enabled globally by the cloud or locally by ingress configuration - Trino checks that ingress/route terminates TLS traffic.

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
auth: 
  passwordAuth: |
    test: cat password.db
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

For more information, refer to the [Trino Client](../../docs/public/user-guide.md#trino-client) section in the Trino Service User's Guide.

For more information, refer to the [DBeaver passwordauth](../../docs/public/user-guide.md#dbeaver-passwordauth) section in the Trino Service User's Guide.

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

It is possible to enable TLS on trino web UI directly inside kubernetes. For this, trino server needs TLS key and certificate. TLS key and certificate can be requested from cert-manager using `certManagerInegration.enabled` parameter. By default, it will create secret `trino-cm-tls-cert` with TLS certificate, TLS key and CA certificate. It is necessary to specify HTTPS scheme for webserver liveness, readiness and startup probes. If you are using kubernetes with NGINX ingress controller, it is possible to pass annotations for ingress controller to work with TLS backend, for example:
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
### Re-encrypt Route in Openshift Without NGINX Ingress Controller

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
causes is there is HTTP traffic between balancers and the cluster. To resolve that issue it is necessary to add the Route name to
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
    hive.metastore.thrift.client.ssl.key=/java-security/cacerts
    hive.metastore.thrift.client.ssl.key-password=changeit
    hive.metastore.thrift.client.ssl.trust-certificate=/java-security/cacerts
    hive.metastore.thrift.client.ssl.trust-certificate-password=changeit
```

To enable secure connection to S3 storage, `s3.endpoint` must include `https://` prefix.

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

## HTTPRoute for K8S Gateway API Support

Qubership platform provides an option to deploy HTTPRoute to expose trino server using K8S gateway API as an alternative to ingress. For more information about k8s Gateway API and HTTPRoute, please refer to the _Official Kubernetes Documentation_ at https://gateway-api.sigs.k8s.io/ and https://gateway-api.sigs.k8s.io/guides/http-routing/.

It is possible to deploy the following three objects: 
* Main HTTPRoute - It is required to replicate the main ingress logic.
* Redirect HTTPRoute - It can be used for redirecting trino user interface client from HTTP to HTTPS when using gateway with custom certificate.
* BackendTLSPolicy - It is required for verifying trino certificate, when TLS is enabled on trino server inside K8S.

The Qubership platform provides the `GATEWAY_SYSTEM_TYPE`, `GATEWAY_SYSTEM_NAME`, and `GATEWAY_SYSTEM_NAMESPACE` parameters, which describe the shared Gateway in the cluster. When `ingress.enabled` and `gateway.enabled` are `null` (the default), the chart derives them independently from `GATEWAY_SYSTEM_TYPE`:
* If `GATEWAY_SYSTEM_TYPE` contains `legacy-ingress`, the Ingress is created.
* If `GATEWAY_SYSTEM_TYPE` contains `gateway-api-default`, the HTTPRoute is created.
* If `GATEWAY_SYSTEM_TYPE` contains both values (for example, `"legacy-ingress, gateway-api-default"`), both the Ingress and the HTTPRoute are created.

Set `ingress.enabled` or `gateway.enabled` explicitly to `true` or `false` to override this behavior regardless of `GATEWAY_SYSTEM_TYPE`. The HTTPRoute requires the Gateway API CRDs in the cluster.

Following configuration parameters are available:

|Name|Type|Default|Description|
|---|---|---|---|
|GATEWAY_SYSTEM_TYPE|`string`|`legacy-ingress`|Specifies whether to create the Ingress (`legacy-ingress`), the HTTPRoute (`gateway-api-default`), or both (`"legacy-ingress, gateway-api-default"`) when `ingress.enabled`/`gateway.enabled` are `null`|
|GATEWAY_SYSTEM_NAME|`string`|`default-external-gateway`|Name of the shared Gateway, used as the default `parentRefs[].name` for HTTPRoutes|
|GATEWAY_SYSTEM_NAMESPACE|`string`|`gateway-system`|Namespace of the shared Gateway, used as the default `parentRefs[].namespace` for HTTPRoutes|
|ingress.enabled|`boolean`|`false`|Specifies if Ingress for trino server is deployed. `false` by default; set to `null` to derive it from `GATEWAY_SYSTEM_TYPE`, or `true`/`false` to override|
|gateway.enabled|`boolean`|`false`|Specifies if HTTPRoute for trino server is deployed. `false` by default; set to `null` to derive it from `GATEWAY_SYSTEM_TYPE`, or `true`/`false` to override|
|gateway.annotations|`object`|`{}`|Annotations for HTTPRoute and related objects|
|gateway.parentRefs|`array`|see below|parentRefs for HTTPRoute. Defaults to a single ref built from `GATEWAY_SYSTEM_NAME` and `GATEWAY_SYSTEM_NAMESPACE`|
|gateway.hostnames|`array`|`[]`|hostnames for HTTPRoute|
|gateway.rules|`array`|see below|rules for HTTPRoute. When `rules[].matches` is not set, it defaults to `path.type=PathPrefix` and `path.value=/`. `backendRefs` in the rule will point to trino server service, but the weight can be configured if needed.|
|gateway.redirectRoute.enabled|`boolean`|`false`|Specifies if redirect HTTPRoute for trino server is deployed|
|gateway.redirectRoute.parentRefs|`array`|see below|parentRefs for redirect HTTPRoute. Defaults to a single ref built from `GATEWAY_SYSTEM_NAME` and `GATEWAY_SYSTEM_NAMESPACE` that targets port `80`|
|gateway.backendTLSPolicy.enabled|`boolean`|`false`|Specifies if the backendTLSPolicy should be deployed|
|gateway.backendTLSPolicy.hostname|`string`|`''`|Hostname for backendTLSPolicy|
|gateway.backendTLSPolicy.caCertificateRefs|`array`|`[]`|caCertificateRefs for backendTLSPolicy|
|gateway.backendTLSPolicy.wellKnownCACertificates|`string`|`""`|wellKnownCACertificates for backendTLSPolicy|
|gateway.backendTLSPolicy.subjectAltNames|`array`|`[]`|subjectAltNames for backendTLSPolicy|

Default `gateway.parentRefs`:
```yaml
gateway:
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: "{{ .Values.GATEWAY_SYSTEM_NAME }}"
      namespace: "{{ .Values.GATEWAY_SYSTEM_NAMESPACE }}"
      # Uncomment if using gateway.redirectRoute (HTTP-to-HTTPS redirect)
      # so this route only targets the Envoy Gateway's HTTPS listener.
      # port: 443
```

Default `gateway.redirectRoute.parentRefs`:
```yaml
gateway:
  redirectRoute:
    parentRefs:
      - group: gateway.networking.k8s.io
        kind: Gateway
        name: "{{ .Values.GATEWAY_SYSTEM_NAME }}"
        namespace: "{{ .Values.GATEWAY_SYSTEM_NAMESPACE }}"
        port: 80
```

Default `gateway.rules`:
```yaml
gateway:
  rules:
    - path:
        type: PathPrefix
        value: /
```

Zero-config (default): with `GATEWAY_SYSTEM_TYPE` set to `gateway-api-default` by the platform, only `hostnames` needs to be set — the HTTPRoute is created automatically, attached to the shared Gateway named by `GATEWAY_SYSTEM_NAME`/`GATEWAY_SYSTEM_NAMESPACE`, and routes `/` to the Trino service using the default `gateway.rules` shown above:
```yaml
gateway:
  hostnames:
    - trino-gateway.your.k8s.hostname
```

The following examples show explicit configuration, overriding the automatic defaults above:

Non tls:
```yaml
  gateway:
    enabled: true
    parentRefs:
      - group: gateway.networking.k8s.io
        kind: Gateway
        name: default-external-gateway
        namespace: envoy-api-gateway
    hostnames:
      - trino-gateway.your.k8s.hostname
    rules:
      - path: {}
```

with TLS:
```yaml
gateway:
  enabled: true
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: tls-envoy-gateway
      namespace: envoy-api-gateway
  hostnames:
    - trino.tls-gateway.your.k8s.hostname
  rules:
    - path:
        type: PathPrefix
        value: /
      backendRefs:
        - name: trino
          port: 8443
  backendTLSPolicy:
    enabled: true
    caCertificateRefs:
      - group: ""
        kind: Secret
        name: trino-server-tls-cert
    hostname: trino.trino.svc.cluster.local
    wellKnownCACertificates: ""
    subjectAltNames: []
```
 ## Redirection of Internal Filesystem Stored Logs to stdout
 
Trino has been configured to redirect all logs, that were previously stored in the internal filesystem, for example, `/data/trino/var/log`,  directly to stdout. This ensures that all logs are captured by the container runtime without writing to the local disk.
 |Configuration Key |	Value |	Purpose |
 |:-----------------:|:-------:|:----------:|
 | `TRINO_LAUNCHER_LOG_FILE` | `/dev/stdout` | Redirects startup and process management logs to the console. |
 | `http-server.log.enabled` | `false` | Disables the creation and rotation of http-request.log files on the internal filesystem. |
 | `http-server.log.console.enabled` | `true` | Activates the console-based logging stream for all HTTP traffic and query events. |

 The above values are configured as defaults as follows:
 ```yaml
 env:
   - name: TRINO_LAUNCHER_LOG_FILE
     value: /dev/stdout
 additionalNodeProperties:
   - http-server.log.enabled=false
   - http-server.log.console.enabled=true  
 ```
## Dynamic Catalogs

> **Warning**: Dynamic catalog management is an **experimental** Trino feature and should be used with caution in production environments.
>
> **Security notice**: `CREATE CATALOG` and `DROP CATALOG` statements are executed as regular SQL queries. This means that **connection credentials supplied in the `CREATE CATALOG` statements, including passwords are visible in plain text in the Trino Web UI query history** and in the query logs. Ensure that access to the Trino UI and logs is appropriately restricted before enabling this feature.

Dynamic catalogs are **enabled by default** in this chart. They allow catalogs to be created and dropped at runtime via SQL, without restarting Trino or modifying `values.yaml`:

```sql
CREATE CATALOG my_catalog USING postgresql WITH ( ... );
DROP CATALOG my_catalog;
```

For more information, refer to the _Trino catalog properties documentation_ at [https://trino.io/docs/current/admin/properties-catalog.html](https://trino.io/docs/current/admin/properties-catalog.html).

### How It Works

When `catalog.store=file` is configured, Trino reads and writes catalog `.properties` files to the coordinator's catalog directory (`/etc/trino/catalog`). As the coordinator runs with a read-only root filesystem, a PersistentVolumeClaim is mounted at that path to provide writable storage. The PVC ensures catalog definitions persist across coordinator restarts.

By default, the chart:

* Creates the `dynamicCatalogPVC` PersistentVolumeClaim.
* Mounts it at `/etc/trino/catalog` in the coordinator pod.
* Adds `catalog-store.properties` pointing to `/etc/trino/catalog`.
* Sets `catalog.management=dynamic`, `catalog.store=file`, and `catalog.prune.update-interval=5s` in the coordinator's `config.properties`.
* Sets `catalog.management=dynamic` in the workers' `config.properties`.
* Uses `coordinator.deployment.strategy.type: Recreate`, because the default `ReadWriteOnce` PVC cannot be mounted by two coordinator pods at the same time.
* Skips mounting the static catalog Secret when dynamic catalog is enabled, to avoid a volume conflict at `/etc/trino/catalog`.

### Disabling Dynamic Catalogs

To use static catalogs defined in `values.yaml` instead, disable `dynamicCatalogPVC`:

```yaml
dynamicCatalogPVC:
  enabled: false

# Restore a RollingUpdate strategy if desired (Recreate is only required for the dynamic catalog PVC)
coordinator:
  deployment:
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 25%
        maxUnavailable: 25%

# Remove the dynamic catalog settings from the default coordinator/worker extra config
# and define static catalogs instead.
server:
  coordinatorExtraConfig: |
    http-server.process-forwarded=IGNORE
  workerExtraConfig: ""

catalogs:
  tpch: |
    connector.name=tpch
    tpch.splits-per-node=4
  tpcds: |
    connector.name=tpcds
    tpcds.splits-per-node=4
```

### Overriding the Dynamic Catalog Configuration

If you need to change the PVC storage class, size, access mode, or reuse an existing claim, override `dynamicCatalogPVC`:

```yaml
dynamicCatalogPVC:
  enabled: true
  storageClass: ""
  accessMode: ReadWriteOnce
  size: 1Gi
  existingClaim: ""
```

If your storage class supports `ReadWriteMany`, you can change `dynamicCatalogPVC.accessMode` to `ReadWriteMany` and restore `RollingUpdate`:

```yaml
dynamicCatalogPVC:
  accessMode: ReadWriteMany

coordinator:
  deployment:
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 25%
        maxUnavailable: 25%
```

**Note**: If you define static catalogs in `values.yaml` while `dynamicCatalogPVC.enabled` is `true`, the chart does not mount the static catalog Secret at `/etc/trino/catalog`, because the PVC is mounted at the same path. Static catalog definitions are ignored when dynamic catalog management is enabled.

### Creating a Catalog at Runtime

Once dynamic catalogs are enabled, use any SQL client connected to Trino to create the catalogs. The example below uses DBeaver to add a PostgreSQL catalog with SSL and disabled certificate validation.

Connect to Trino in DBeaver and execute:

```sql
CREATE CATALOG my_postgres USING postgresql
WITH (
  "connection-url" = 'jdbc:postgresql://pg-patroni.postgres-tls:5432/postgres?ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory',
  "connection-user" = 'postgresuser',
  "connection-password" = 'postgrespassword'
);
```

To verify if the catalog was created:

```sql
SHOW CATALOGS;
```

To remove a catalog:

```sql
DROP CATALOG my_postgres;
```

**Note**: With `catalog.store=file`, the catalog definition is written to `/etc/trino/catalog/my_postgres.properties` on the PVC and survives coordinator restarts. With `catalog.store=memory` the catalog exists only until the coordinator process is completed.

**Security reminder**: The `connection-password` value in the `CREATE CATALOG` statement is stored unencrypted in the Trino query history and is visible to anyone with access to the Trino Web UI. Restrict the UI access accordingly.

## Using SeaweedFS with the Hive Connector

The Hive connector can read and write tables whose locations use the `seaweedfs://` scheme—e.g., when the Hive Metastore warehouse is stored in SeaweedFS. Trino's native S3 file‑system support cannot open `seaweedfs://` locations, so this catalog relies on Hadoop file‑system support (`fs.hadoop.enabled=true`) together with the SeaweedFS Hadoop client. Because a catalog can employ only a single file‑system implementation, it cannot also enable `fs.native-s3.enabled`.

The Qubership Trino image bundles the `seaweedfs-hadoop3-client` JAR in the `hdfs/` directories of the `hive`, `iceberg`, `delta-lake`, `hudi`, and `lakehouse` plugins. The Hive Metastore must also support SeaweedFS, as provided by the Qubership Hive Metastore image.

The JAR does not automatically register the `seaweedfs` scheme with Hadoop, so you must define the scheme in a `core-site.xml` file that is present on the coordinator and on every worker. The filer host and port are not configured in Trino; the client derives them from the `seaweedfs://<host>:<port>/…` table and schema locations stored in the Hive Metastore (for example, from its `s3.warehouseDir` value `metastore.warehouse.dir` or an explicit location). The gRPC port defaults to the filer port plus 10,000.

Parameters example:

```yaml
coordinator:
  additionalConfigFiles:
    catalog-store.properties: | # required for dynamic catalogs
      catalog.config-dir=/etc/trino/catalog
    core-site.xml: |
      <configuration>
        <property><name>fs.seaweedfs.impl</name><value>seaweed.hdfs.SeaweedFileSystem</value></property>
        <property><name>fs.AbstractFileSystem.seaweedfs.impl</name><value>seaweed.hdfs.SeaweedAbstractFileSystem</value></property>
      </configuration>
worker:
  additionalConfigFiles:
    core-site.xml: |
      <configuration>
        <property><name>fs.seaweedfs.impl</name><value>seaweed.hdfs.SeaweedFileSystem</value></property>
        <property><name>fs.AbstractFileSystem.seaweedfs.impl</name><value>seaweed.hdfs.SeaweedAbstractFileSystem</value></property>
      </configuration>
```

To create the catalog:

```sql
CREATE CATALOG hive_seaweedfs USING hive
WITH (
  "hive.metastore.uri" = 'thrift://hive-metastore.hive-metastore:9083',
  "fs.hadoop.enabled" = 'true',
  "hive.config.resources" = '/etc/trino/core-site.xml',
  "hive.non-managed-table-writes-enabled" = 'true'
);
```

 Hive Metastore version 4 converts tables created by Trino into external tables. Trino rejects writes to such tables with the error `Cannot write to non-managed Hive table` unless the property `hive.non-managed-table-writes-enabled` is set to `'true'`.

By default, a schema is created under the Hive Metastore warehouse directory, and its tables are created under the schema. To store a schema or a table at an explicit location, set the `location` schema property or the `external_location` table property to a `seaweedfs://` URI:

```sql
CREATE SCHEMA hive_seaweedfs.custom_schema
WITH (location = 'seaweedfs://seaweedfs-filer.seaweedfs:8888/custom/custom_schema');

CREATE TABLE hive_seaweedfs.custom_schema.external_table (id integer, name varchar)
WITH (
  external_location = 'seaweedfs://seaweedfs-filer.seaweedfs:8888/custom/external_table_data',
  format = 'PARQUET'
);
```

Tables created in a schema with an explicit `location` are stored under that location. Writing to a table with `external_location` also requires `hive.non-managed-table-writes-enabled` to be `true`.

To check the setup, create a schema and a table, and write to it:

```sql
CREATE SCHEMA hive_seaweedfs.test_schema;
CREATE TABLE hive_seaweedfs.test_schema.test_table (id integer, name varchar);
INSERT INTO hive_seaweedfs.test_schema.test_table VALUES (1, 'trino'), (2, 'seaweedfs');
SELECT * FROM hive_seaweedfs.test_schema.test_table;
```

**Note**: The Trino coordinator and workers must reach the SeaweedFS filer over HTTP (port `8888` by default) and gRPC (port `18888` by default). This configuration works with a filer without authentication. For an authenticated filer, the SeaweedFS client reads its settings from a `security.toml` file, which must be mounted into the coordinator and worker pods.

# Installation

The installation process is specified below.

## Before You Begin

Installation [prerequisites](#prerequisites) should be fulfilled to prepare for the installation.

## On-Prem

The deployment for on-premises is described below.

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

Trino service does not support rollback. In order to install an older version, perform the following steps:

1. Clear the Trino service's namespace by recreating it.

```
kubectl delete namespace <trino_namespace>

kubectl create namespace <trino_namespace>
```

2. Run installation with the older version.
