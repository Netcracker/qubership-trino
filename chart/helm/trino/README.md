
Trino
===========

Fast distributed SQL query engine for big data analytics that helps you explore your data universe


## Configuration

The following table lists the configurable parameters of the Trino chart and their default values.

| Parameter                | Description             | Default                                           |
| ------------------------ | ----------------------- |---------------------------------------------------|
| `image.repository` |  | `"trinodb/trino"`                                 |
| `image.pullPolicy` |  | `"IfNotPresent"`                                  |
| `image.tag` |  | `464`                                             |
| `imagePullSecrets` |  | `[]`               |
| `server.workers` |  | `2`                                               |
| `server.node.environment` |  | `"production"`                                    |
| `server.node.dataDir` |  | `"/data/trino"`                                   |
| `server.node.pluginDir` |  | `"/usr/lib/trino/plugin"`                         |
| `server.log.trino.level` |  | `"INFO"`                                          |
| `server.config.path` |  | `"/etc/trino"`                                    |
| `server.config.http.port` |  | `8080`                                            |
| `server.config.https.enabled` |  | `false`                                           |
| `server.config.https.port` |  | `8443`                                            |
| `server.config.https.keystore.path` |  | `""`                                              |
| `server.config.authenticationType` |  | `""`                                              |
| `server.config.query.maxMemory` |  | `"4GB"`                                           |
| `server.exchangeManager` |  | `{}`                                    |
| `server.workerExtraConfig` |  | `""`                                              |
| `server.coordinatorExtraConfig` |  | `""`                                              |
| `server.autoscaling.enabled` |  | `false`                                           |
| `server.autoscaling.maxReplicas` |  | `5`                                               |
| `server.autoscaling.targetCPUUtilizationPercentage` |  | `50`                                              |
| `server.autoscaling.targetMemoryUtilizationPercentage` |  | `80`                                              |
| `accessControl` |  | `{}`                                              |
| `additionalNodeProperties` |  | `{}`                                              |
| `additionalConfigProperties` |  | `{}`                                              |
| `additionalLogProperties` |  | `{}`                                              |
| `additionalExchangeManagerProperties` |  | `{}`                                              |
| `eventListenerProperties` |  | `{}`                                              |
| `catalogs` |  | `{"tpcds":"connector.name=tpcds\ntpcds.splits-per-node=4\n","tpch":"connector.name=tpch\ntpch.splits-per-node=4\n"}`                                              |
| `additionalCatalogs` | Deprecated | `{}`                                              |
| `env` |  | `[]`                                              |
| `envFrom` |  | `[]`                                              |
| `initContainers` |  | `{}`                                              |
| `sidecarContainers` |  | `{}`                                              |
| `securityContext` |  | `{"runAsGroup":1000,"runAsUser":1000}`                                            |
| `shareProcessNamespace.coordinator` |  | `false`                                           |
| `shareProcessNamespace.worker` |  | `false`                                           |
| `service.type` |  | `"ClusterIP"`                                     |
| `service.port` |  | `8080`                                            |
| `auth` |  | `{}`                                              |
| `serviceAccount.create` |  | `false`                                           |
| `serviceAccount.name` |  | `""`                                              |
| `serviceAccount.annotations` |  | `{}`                                              |
| `secretMounts` |  | `[]`                                              |
| `coordinator.deployment.progressDeadlineSeconds` |  | `600`                                            |
| `coordinator.deployment.revisionHistoryLimit` |  | `10`                                            |
| `coordinator.deployment.strategy` |  | `{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"}`                                            |
| `coordinator.jvm.maxHeapSize` |  | `"8G"`                                            |
| `coordinator.jvm.gcMethod.type` |  | `"UseG1GC"`                                       |
| `coordinator.jvm.gcMethod.g1.heapRegionSize` |  | `"32M"`                                           |
| `coordinator.config.memory.heapHeadroomPerNode` |  | `""`                                              |
| `coordinator.config.query.maxMemoryPerNode` |  | `"1GB"`                                           |
| `coordinator.additionalJVMConfig` |  | `{}`                                              |
| `coordinator.additionalExposedPorts` |  | `{}`                                              |
| `coordinator.resources` |  | `{}`                                              |
| `coordinator.livenessProbe` |  | `{}`                                              |
| `coordinator.readinessProbe` |  | `{}`                                              |
| `coordinator.nodeSelector` |  | `{}`                                              |
| `coordinator.tolerations` |  | `[]`                                              |
| `coordinator.affinity` |  | `{}`                                              |
| `coordinator.additionalConfigFiles` |  | `{}`                                              |
| `coordinator.annotations` |  | `{}`                                              |
| `coordinator.labels` |  | `{}`                                              |
| `coordinator.secretMounts` |  | `[]`                                              |
| `worker.deployment.progressDeadlineSeconds` |  | `600`                                            |
| `worker.deployment.revisionHistoryLimit` |  | `10`                                            |
| `coordinator.deployment.strategy` |  | `{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"}`                                            |
| `worker.jvm.maxHeapSize` |  | `"8G"`                                            |
| `worker.jvm.gcMethod.type` |  | `"UseG1GC"`                                       |
| `worker.jvm.gcMethod.g1.heapRegionSize` |  | `"32M"`                                           |
| `worker.config.memory.heapHeadroomPerNode` |  | `""`                                              |
| `worker.config.query.maxMemoryPerNode` |  | `"1GB"`                                           |
| `worker.additionalJVMConfig` |  | `{}`                                              |
| `worker.additionalExposedPorts` |  | `{}`                                              |
| `worker.resources` |  | `{}`                                              |
| `worker.livenessProbe` |  | `{}`                                              |
| `worker.readinessProbe` |  | `{}`                                              |
| `worker.gracefulShutdown` |  |  `{"enabled":false,"gracePeriodSeconds":120}`                                              |
| `worker.nodeSelector` |  | `{}`                                              |
| `worker.tolerations` |  | `[]`                                              |
| `worker.affinity` |  | `{}`                                              |
| `worker.additionalConfigFiles` |  | `{}`                                              |
| `worker.annotations` |  | `{}`                                              |
| `worker.labels` |  | `{}`                                              |
| `worker.secretMounts` |  | `[]`                                              |
| `kafka.mountPath` |  | `"/etc/trino/schemas"`                            |
| `kafka.tableDescriptions` |  | `{}`                                              |
| `commonLabels` | Labels that get applied to every resource's metadata | `{}`                                              |
| `ingress.enabled` |  | `false`                                           |
| `ingress.className` |  | `""`                                              |
| `ingress.annotations` |  | `{}`                                              |
| `ingress.hosts` |  | `[]`                                              |
| `ingress.tls` |  | `[]`                                              |
| `networkPolicy.enabled` |  | `false`                                              |
| `networkPolicy.ingress` |  | `[]`                                              |
| `networkPolicy.egress` |  | `[]`                                              |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

