This guide provides information about the main security parameters and its configuration in the Trino service.

## Exposed Ports

List of ports used by Trino are as follows: 

| Port | Service                       | Description                                                                                                                                                                                                                                                                                |
|------|-------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 8080 | Trino                         | Port for HTTP communications.                                                                                                                                                                                                                                         |
| 8443 | Trino                         | Port for HTTPS communications.                                                                                                                                                                                                                                |
| JMX exporter port | Trino                         | Port for JMX exporter. There is no default value. It is specified if required.                                                                                                                                                                                                                                |

## Secure Protocols

It is possible to enable TLS in Trino. This process is described in the respective [Installation](/docs/public/installation.md#httpstls-for-trino) guide.

## Changing Credentials

Trino does not contain a user management mechanism and there is no ability to change the credentials in runtime. The only one way to specify or change the credentials is specifying in a deployment parameters. By default, there are no Trino users OOB. You can create users via deployment parameters as well. This process is described in respective [Installation](/docs/public/installation.md#enabling-password-authentication) guide.

Credentials for underlying services are managed in the underlying services. You can configure them in Trino parameters. For more details refer to:
* [Trino Service Installation Procedure](/docs/public/installation.md#configure-trino-connectors-to-use-tlsssl)
* [Trino Service User's Guide](/docs/public/user-guide.md#trino-connectors)

There is no mechanism in Trino to manage credentials for Trino. If the external system is used to manage Trino users, the credentials can be managed there. 

## Configuring Permissions

It is possible to configure user permissions via access control configuration. This process is described in the respective [Installation](/docs/public/installation.md#parameters) guide. 

## Security Events

To identify the security events in logs, the following packages and key words can be used:
| Security event | Package | Key words |
|----------------|---------|-----------|
| Authentication | io.trino.server.security | "Authentication", "Login", "Failed login" |
| Authorization | io.trino.server.security | "Authorization failed", "Access denied", "Permission denied" |
| Data access | io.trino.execution | Data base operations key words |
| Connection | io.trino.server.protocol | "Connection accepted", "Connection failed" |

## Session Management

Trino does not support session management. For these purposes, it is recommended to integrate Trino with external user management systems. You may find more detailsin the external Trino documentation: [Security](https://trino.io/docs/current/security.html).
