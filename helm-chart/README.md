# The Things Join Server Helm Chart

The Things Join Server is a LoRaWAN Join Server with claiming capabilities. It supports LoRaWAN Backend Interfaces 1.0 and 1.1 and LoRaWAN 1.0.x and 1.1.

This folder contains a Helm chart that bootstraps The Things Join Server on a Kubernetes cluster.

Prerequisites:

- Helm CLI ([install](https://helm.sh/docs/intro/install/))
- Local: Minikube ([install](https://minikube.sigs.k8s.io/docs/start/))
- Cloud: Amazon Web Services (AWS) resources
  - AWS Elastic Kubernetes Service (EKS) cluster ([documentation](https://aws.amazon.com/eks/getting-started/))
  - AWS resources for The Things Join Server ([deploy](../aws))

## Deploy

### Amazon Web Services

The Things Join Server requires a proxy to terminate TLS. Currently, the only supported proxy is Traefik. [See Helm chart documentation](https://github.com/traefik/traefik-helm-chart).

The Things Join Server uses a sevice account that is linked to the IAM role to access AWS resources. This is the default configuration.

```yaml
# aws.values.yaml

proxy:
  traefik:
    enabled: true

ingress:
  hosts:
    - host: "" # Host
  tls:
    - secretName: "" # Secret name containing tls.crt and tls.key
      hosts:
        - "" # Host
```

Enter the host and TLS server certificate secret name.

Install:

```bash
$ helm upgrade --install ttjs -f aws.values.yaml .
```

### Local

Install Traefik for local use:

```bash
$ helm repo add traefik https://traefik.github.io/charts
$ helm upgrade --install traefik traefik/traefik \
  --set service.type=NodePort \
  --set ports.web.expose=false
```

Generate a TLS server certificate that is valid for `localhost`:

```bash
$ mkcert localhost 127.0.0.1 ::1
```

Kubernetes resources for the local deployment:

```yaml
# localhost.yaml

apiVersion: v1
kind: Secret
metadata:
  name: localhost
type: kubernetes.io/tls
data:
  tls.crt: "" # localhost+2.pem (base64)
  tls.key: "" # localhost+2-key.pem (base64)
---
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
type: Opaque
data:
  aws_access_key_id: "" # AWS access key ID (base64)
  aws_secret_access_key: "" # AWS secret access key (base64)
```

> The AWS credentials are used to assume The Things Join Server IAM role.

Deploy:

```bash
$ kubectl apply -f localhost.yaml
```

Prepare the configuration, adapt as needed:

```yaml
# localhost.values.yaml

proxy:
  traefik:
    enabled: true

aws:
  region: eu-central-1
  secretName: aws-credentials
  roleArn: arn:aws:iam::123456789012:role/the-things-join-server

serviceAccount:
  create: false

ingress:
  hosts:
    - host: localhost
  tls:
    - secretName: localhost
      hosts:
        - localhost
```

Install:

```bash
$ helm upgrade --install ttjs -f localhost.values.yaml .
```

Expose a tunnel to Traefik:

```bash
$ minikube service traefik --https --url
```

Verify that you can access The Things Join Server by navigating to `https://localhost:<port>/api/v2/openapi.json`.

## Legal

Copyright © 2022 The Things Industries B.V.
