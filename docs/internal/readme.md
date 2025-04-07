**This guide should be read after [architecture.md](/docs/public/architecture.md) and [installation.md](/docs/public/installation.md)**

## Repository structure

* `chart` - helm charts for trino.
* `docker` - files for platform trino image building.
* `docs` - trino documentation.
* `/` - other files in the root folder.

## How to start

Trino uses community helm charts from https://github.com/trinodb/charts with some minor changes(images are taken from manifest or labels are adjusted to cloud-release requirements).

Trino platform image is based on community image https://hub.docker.com/r/trinodb/trino. The changes in platform image compared to community image are:

* Custom entrypoint that add logic for importing certificates to java truststore
* Dockerfile add this entrypoint and adds necessary permissions.

### Deploy to k8s

See [installation.md](/docs/public/installation.md)

### How to debug and troubleshoot

Trino authentication is different from most other services, so it's best to be familiar with https://trino.io/docs/current/security/authentication-types.html . In platform, [Password file authentication](https://trino.io/docs/current/security/password-file.html) is used. Note, that for trino password file authentication, enabling TLS on trino itsellf is not necessarily strictly speaking, it is possible to enable TLS on [ load balancer proxy](https://trino.io/docs/current/security/tls.html#approaches), or ingress in our case.

## Useful links:

* https://github.com/trinodb/trino - trino github page
* https://github.com/trinodb/charts - trino helm charts location
* https://hub.docker.com/r/trinodb/trino - trino docker image
* https://trino.io/docs/current/ - trino documentation
* https://trino.io/docs/current/connector.html - trino connector documentation
* https://trino.io/docs/current/security/authentication-types.html - trino password authentication
