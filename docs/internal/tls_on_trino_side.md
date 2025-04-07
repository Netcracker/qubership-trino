### Enable HTTPS/TLS for Trino Server

**Warning**: After enabling TLS, the WEB UI will not be available over HTTP. It will be available only over HTTPS.

#### Using Manual Certificate for Trino

1.1 Generate self-signed certificates for the Trino service.

1.2 Create a configuration file for generating the SSL certificate.

```bash
cat <<EOF > openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
prompt = no

[req_distinguished_name]
CN = Trino.svc

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[alt_names]
IP.1 = 127.0.0.1
IP.2 = [IP address workers nodes]
...
DNS.1 = trino
DNS.2 = trino.trino
DNS.3 = trino.trino.svc
EOF
```

1.3 Create a CA certificate.

```bash
openssl req -days 730 -nodes -new -x509 -keyout ca.key -out ca.crt -subj "/CN=Trino.svc"
```

1.4 Create a private key.

```bash
openssl genrsa -out key.pem 2048
```

1.5 Create a certificate request.

```bash
openssl req -new -key key.pem -out req.pem -config openssl.cnf
```

1.6 Sign the certificate request using the CA file.

```bash
openssl x509 -req -in req.pem -CA ca.crt -CAkey ca.key -CAcreateserial -out cert.pem -days 365 -extensions v3_req -extfile openssl.cnf
```

1.7 Combine the private key and certificate into one file.

```bash
cat key.pem cert.pem > tls-combined.pem | base64
```

1.8 Add key values to the values.yaml

Example configuration is as follows.

```yaml 
server:
  config:
    https:
      enabled: true
      port: 8443
tls:
  enabled: true
  certificates:
    tls: "value_of_tls-combined.pem_base64_encoded"
```

#### Using Cert-manager to get the Certificate

**Note**: Cert-manager must be installed in the cluster for this to work.

2.1 Use cluster-issuer to create a certificate.

Example configuration is as follows.

```yaml
server:
  config:
    https:
      enabled: true
      port: 8443
tls:
  enabled: true
  generateCerts:
    enabled: true
    secretName: trino-cm-tls-cert
    secretMounts:
      - mountPath: /etc/trino/certs/
    clusterIssuerName: common-cluster-issuer
    subjectAlternativeName:
      additionalIpAddresses: [IP address workers nodes]
```

2.2 Use the custom issuer to create a certificate.

Example configuration is as follows.

```yaml
server:
  config:
    https:
      enabled: true
      port: 8443
tls:
  enabled: true
  generateCerts:
    enabled: true
    clusterIssuerName: <set_custom_issuer_name>
    subjectAlternativeName:
      additionalIpAddresses: [IP address workers nodes]
```

### TLS Parameters

The TLS parameters are specified in the table below.

| Parameter                                                        | Description                                                                                                                    | Default                 |
|------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|-------------------------|
| `server.config.https.enabled`                                    | It enables HTTPS for the Trino server.                                                                                         | `false`                 |
| `server.config.https.port`                                       | It specifies the HTTPS port for the Trino HTTP server.                                                                         | `8443`                  |
| `server.config.https.keystore.path`                              | The path to the keystore. It is used when HTTPS is enabled.                                                                    | `""`                    |
| `tls.generateCerts.enabled`                                      | The parameter to integrate cert-manager.                                                                                       | `false`                 |
| `tls.generateCerts.secretName`                                   | The name of the certificate for a TLS operation.                                                                               | `trino-tls`             |
| `tls.generateCerts.clusterIssuerName`                            | The name of the issuer to create a certificate for a TLS operation.                                                            | `common-cluster-issuer` |
| `tls.generateCerts.subjectAlternativeName.additionalIpAddresses` | An array of IP addresses for the external access to Trino using HTTPS/TLS.                                                         | `[]`                    |
| `service.nodePort`                                               | If `service.type` is "NodePort", set the value from a range 30000-32767 or leave it empty, Kubernetes will set it automatically. |                         |
| `extraSecrets`                                                   | Allows to create custom secrets to pass them to pods during the deployments. The format for secret data is "key/value" where key (can be templated) is the name of the secret that will be created, value - an object with the standard 'data' or 'stringData' key (or both). The value associated with those keys must be a string (can be templated). | {}                      |
