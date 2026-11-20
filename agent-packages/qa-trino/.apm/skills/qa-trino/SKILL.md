---
name: qa-trino
description: Plan and verify testing of a Qubership Trino change when the repository has no automated tests — deploy-based verification of the coordinator and workers, dynamic catalog management, static and Hive catalog wiring, TLS and password authentication, worker autoscaling, and the template guards that fail rendering. Triggers when the user asks how to test a Trino chart or image change, why the coordinator will not start, or why a query fails on a worker. Do NOT run automatically.
---

## Read this first

**This repository has no tests.** No unit tests, no integration tests, no Helm test hooks, no
chart-testing, no kubeconform.

The only static gates are:

1. `docker-transfer/validation.py` — fails the transfer image build when `values.yaml` defaults
   drift from `values.schema.json`.
2. Template `fail` guards — a handful of invalid combinations that abort rendering.
3. The 76 KB `values.schema.json`, enforced only when Helm processes values.

Everything else needs a deployment. Report coverage as "verified by deployment", never
"tests pass".

---

## The component

`chart/helm/trino` is a fork of the upstream Trino chart (`appVersion 484`, chart `1.45.0`).

Topology: **one coordinator** (replicas hardcoded to `1`) plus `server.workers` workers
(default `2`). **Non-HA** — there is no HA scheme, and **no rollback**: reverting requires
deleting and recreating the namespace.

Ports: `8080` HTTP, `8443` HTTPS.

---

## Dynamic catalog management is ON by default — and it changes everything

Defaults set `catalog.management=dynamic`, `catalog.store=file` and
`catalog.prune.update-interval=5s` on both coordinator and workers. Consequences that produce
real defects:

- **Static `catalogs` conflict.** Any static catalog entry must be nulled
  (`catalogs: {tpch: ~, tpcds: ~, hive: ~}`) or the catalog Secret mount collides with the PVC
  at `/etc/trino/catalog` and the coordinator will not start.
- **`server.coordinatorExtraConfig` replaces, not merges.** Helm does not merge strings, so
  overriding it silently drops `http-server.process-forwarded=IGNORE`.
- **Workers need `catalog.management=dynamic` too**, or task dispatch fails with
  `StaticCatalogManager`.
- **`coordinator.deployment.strategy.type` must be `Recreate` with `rollingUpdate: ~`**, else
  rendering fails with `spec.strategy.rollingUpdate: Forbidden`.
- **Credentials leak.** `CREATE CATALOG` statements expose credentials in query history and the
  UI. This is a documented security notice — if a test creates a catalog, treat the query
  history as potentially sensitive evidence.

Catalog changes are the single highest-risk area of this chart. Any test plan touching catalogs
must cover both a dynamic-created catalog and a statically configured one.

---

## Template guards — cheap negative tests

Render must **fail** for each of these; verify the failure, not just the happy path:

| Condition | Guard |
| --- | --- |
| `opa.policy` and `opa.policyConfigMap` both set | fail |
| neither OPA policy source set while `opa.enabled` | fail |
| `opa.enabled` with Trino < 438 on the default community image | fail |
| `server.keda.enabled` and `server.autoscaling.enabled` together | fail |
| `server.keda.enabled` with empty `server.keda.triggers` | fail |
| `networkPolicy.enabled` with `service.type: NodePort` | fail |

---

## Variants that must be exercised

| Variant | Keys | Notes |
| --- | --- | --- |
| Plain coordinator + workers | defaults | baseline |
| Static catalogs | `catalogs` | must null the default dynamic path |
| Hive catalog | `catalogs.hive.*`, `hive.host/port` | needs a live metastore (9083) |
| Hive 4 external tables | `hive.non-managed-table-writes-enabled=true` | Hive 4 makes Trino tables external; writes fail without it |
| SeaweedFS | `core-site.xml` with `fs.seaweedfs.impl` | **required on coordinator and every worker**; cannot combine with `fs.native-s3.enabled` |
| TLS | `tls.enabled`, `tls.generateCerts.*` | keystore path hardcoded `/etc/trino/certs/tls-combined.pem`; enabling TLS disables the Web UI over HTTP |
| Password auth | `auth.passwordAuth` / `auth.passwordAuthSecret`, `auth.groups` | supported **only behind a TLS-terminating ingress/route** |
| Worker autoscaling | `server.autoscaling.*` **or** `server.keda.*` | mutually exclusive |
| Access control | `accessControl.type: configmap`, `rules` | verify rules actually deny |
| OpenShift | `PAAS_PLATFORM: OPENSHIFT` | `runAsUser`/`fsGroup`/`runAsGroup` omitted |

---

## What a deployment test must include

1. `helm template` for the changed values, plus one guard case that must fail.
2. Coordinator reaches `STARTING`/`ACTIVE`; every worker joins (`/v1/info`, `system.runtime.nodes`).
3. A query that exercises **both** coordinator and worker (a join or aggregate over data), not
   just `SELECT 1`.
4. Each configured catalog is queryable — for Hive, create and read a table.
5. After any catalog change made at runtime, confirm workers see it (dispatch actually works).
6. TLS/auth: connect with the configured authentication mode over the configured scheme.
7. If autoscaling or KEDA is on: scale out and back, and confirm no coordinator conflict.

State which steps were skipped and why.

---

## Known documentation drift

`installation.md` still shows community defaults — `image.repository trinodb/trino`,
`image.tag "392"`, and `catalogs` containing tpch/tpcds — while `values.yaml` ships
`ghcr.io/netcracker/qubership-trino:main` and `catalogs: {}`. It also documents
`ingress.web.enabled` where the key is `ingress.enabled`.

Also note key-naming inconsistency across the platform: Trino uses lowercase
`s3.accesskey`/`s3.secretkey`, while `hive-metastore` uses camelCase `s3.accessKey/secretKey`.
A shared fixture that reuses one spelling will fail against the other.

**`values.yaml` and `values.schema.json` are the ground truth**, not the docs table.

---

## Reviewing a change

- Does it touch catalog management, the coordinator strategy, TLS, or auth? Those four carry the
  traps above and each deserves a dedicated scenario.
- If a query fails on workers but succeeds on the coordinator, suspect catalog propagation before
  suspecting the query.
- Remember there is no rollback: an upgrade test needs a disposable namespace.
- Propose the cheapest durable check — a schema constraint or the existing template `fail` guards
  extended — since no automated suite exists.
