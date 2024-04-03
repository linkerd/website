+++
title = "Automatically Rotating Webhook TLS Credentials"
description = "Use cert-manager to automatically rotate webhook TLS credentials."
+++

The Linkerd control plane contains several components, called webhooks, which
are called directly by Kubernetes itself. The traffic from Kubernetes to the
Linkerd webhooks is secured with TLS and therefore each of the webhooks requires
a secret containing TLS credentials. These certificates are different from the
ones that the Linkerd proxies use to secure pod-to-pod communication and use a
completely separate trust chain. For more information on rotating the TLS
credentials used by the Linkerd proxies, see
[Automatically Rotating Control Plane TLS Credentials](../use_external_certs/).

By default, when Linkerd is installed with the Linkerd CLI or with the Linkerd
Helm chart, TLS credentials are automatically generated for all of the webhooks.
If these certificates expire or need to be regenerated for any reason,
performing a [Linkerd upgrade](../upgrade/) (using the Linkerd CLI or using
Helm) will regenerate them.

Unless absolutely necessary, it is recommended to allow the CLI/Helm to create
and update webhook certificates automatically through the install and upgrade
process. However, if you need these webhook certificates to be rotated
automatically on a regular basis, it is possible to use cert-manager to
automatically manage them.

{{< trylpt >}}

## Install Cert manager

As a first step,
[install cert-manager on your cluster](https://cert-manager.io/docs/installation/)
and create the namespaces that cert-manager will use to store its
webhook-related resources. For simplicity, we suggest using the default
namespace linkerd uses:

```bash
# control plane core
kubectl create namespace linkerd
kubectl label namespace linkerd \
  linkerd.io/is-control-plane=true \
  config.linkerd.io/admission-webhooks=disabled \
  linkerd.io/control-plane-ns=linkerd
kubectl annotate namespace linkerd linkerd.io/inject=disabled

# viz (ignore if not using the viz extension)
kubectl create namespace linkerd-viz
kubectl label namespace linkerd-viz linkerd.io/extension=viz

# jaeger (ignore if not using the jaeger extension)
kubectl create namespace linkerd-jaeger
kubectl label namespace linkerd-jaeger linkerd.io/extension=jaeger
```

{{< note >}} The following namespace-bound templates and commands can be re-used
for Linkerd extensions including viz and jaeger by modifying the namespace of
each to match that of the extension. {{< /note >}}

## Give cert-manager necessary RBAC permissions

By default cert-manager will only create certificate secrets in the namespace
where it is installed. Linkerd and its extensions, however, require the cert
secrets to be created in the namespaces where they run. To do this we will
create a `ServiceAccount` for cert-manager in the appropriate namespaces with
the required permissions.

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cert-manager
  namespace: linkerd
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cert-manager-secret-creator
  namespace: linkerd
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "get", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cert-manager-secret-creator-binding
  namespace: linkerd
subjects:
  - kind: ServiceAccount
    name: cert-manager
    namespace: linkerd
roleRef:
  kind: Role
  name: cert-manager-secret-creator
  apiGroup: rbac.authorization.k8s.io
EOF
```

## Create the trust root issuer

To begin, create a self-signing `ClusterIssuer` for the Linkerd trust root
certificate.

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: linkerd-trust-root-issuer
spec:
  selfSigned: {}
EOF
```

## Create a trust root certificate

Now create a cert-manager `Certificate` resource which uses the
previously-created `ClusterIssuer`:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-trust-anchor
  namespace: linkerd
spec:
  commonName: root.linkerd.cluster.local
  isCA: true
  duration: 87600h0m0s
  renewBefore: 87264h0m0s
  issuerRef:
    name: linkerd-trust-root-issuer
    kind: ClusterIssuer
  privateKey:
    algorithm: ECDSA
  secretName: linkerd-trust-anchor
EOF
```

## Create Linkerd webhook issuer

Using the previously-generated trust root certificate, create a separate
`ClusterIssuer` for Linkerd webhook certificates:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: linkerd-webhook-issuer
  namespace: linkerd
spec:
  ca:
    secretName: linkerd-trust-anchor
EOF
```

## Issuing certificates and writing them to secrets

Finally, we can create cert-manager `Certificate` resources which use the
issuers to generate the desired certificates:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-policy-validator
  namespace: linkerd
spec:
  secretName: linkerd-policy-validator-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: linkerd-webhook-issuer
    kind: Issuer
  commonName: linkerd-policy-validator.linkerd.svc
  dnsNames:
  - linkerd-policy-validator.linkerd.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
    encoding: PKCS8
  usages:
  - server auth
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-proxy-injector
  namespace: linkerd
spec:
  secretName: linkerd-proxy-injector-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: linkerd-webhook-issuer
    kind: Issuer
  commonName: linkerd-proxy-injector.linkerd.svc
  dnsNames:
  - linkerd-proxy-injector.linkerd.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
  - server auth
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-sp-validator
  namespace: linkerd
spec:
  secretName: linkerd-sp-validator-k8s-tls
  duration: 24h
  renewBefore: 1h
  issuerRef:
    name: linkerd-webhook-issuer
    kind: Issuer
  commonName: linkerd-sp-validator.linkerd.svc
  dnsNames:
  - linkerd-sp-validator.linkerd.svc
  isCA: false
  privateKey:
    algorithm: ECDSA
  usages:
  - server auth
EOF
```

## Summary & Validation

Below are the resources created for managing Linkerd webhook certificates with
cert-manager:

- Namespace: `linkerd` (to store certificates and secrets)
- RBAC Permissions: ServiceAccount, Role, and RoleBinding in the `linkerd`
  namespace for cert-manager
- ClusterIssuer: `linkerd-trust-root-issuer` (self-signed ClusterIssuer)
- Certificate: `linkerd-trust-anchor` (in the `linkerd` namespace, referencing
  `linkerd-trust-root-issuer`)
- Issuer: `linkerd-webhook-issuer` (to manage Linkerd webhook certificates)
- Certificates & Secrets:
  - `linkerd-policy-validator`: Policy validator certificate and secret
  - `linkerd-proxy-injector`: Proxy injector certificate and secret
  - `linkerd-sp-validator`: Service profile validator certificate and secret

To validate creation and status, run the following commands:

```bash
# Check namespace creation
kubectl get namespaces linkerd

# Check RBAC permissions
kubectl get serviceaccount,role,rolebinding -n linkerd

# Check ClusterIssuer creation
kubectl get clusterissuers linkerd-trust-root-issuer

# Check Certificate creation
kubectl get certificates -n linkerd

# Check Issuer creation
kubectl get issuers.cert-manager.io -n linkerd
```

## Consuming cert-manager webhook certificates

To have Linkerd consume cert-manager created certificates you will need to add
the following to your values file or pass them in as flags at runtime.

| Field                                 | Value                              |
| ------------------------------------- | ---------------------------------- |
| `proxyInjector.externalSecret`        | true                               |
| `proxyInjector.injectCaFromSecret`    | "linkerd-proxy-injector-k8s-tls"   |
| `policyValidator.externalSecret`      | true                               |
| `policyValidator.injectCaFromSecret`  | "linkerd-policy-validator-k8s-tls" |
| `profileValidator.externalSecret`     | true                               |
| `profileValidator.injectCaFromSecret` | "linkerd-sp-validator-k8s-tls"     |

## Using these credentials with CLI installation

To configure Linkerd to use the credentials from cert-manager rather than
generating its own:

````bash
# first, install the Linkerd CRDs
linkerd install --crds | kubectl apply -f -

# install the Linkerd control plane, using the credentials
# from cert-manager
linkerd install \
  --set policyValidator.externalSecret=true \
  --set-file policyValidator.injectCaFromSecret=linkerd-policy-validator-k8s-tls \
  --set proxyInjector.externalSecret=true \
  --set-file proxyInjector.injectCaFromSecret=linkerd-proxy-injector-k8s-tls \
  --set profileValidator.externalSecret=true \
  --set-file profileValidator.injectCaFromSecret=linkerd-sp-validator-k8s-tls \
  | kubectl apply -f -

## Installing with Helm

A similar pattern can be used with Helm:

```bash
# first install the linkerd-crds chart
helm install linkerd-crds linkerd/linkerd-crds \
  -n linkerd --create-namespace

# then install the linkerd-control-plane chart
# (see note below)
helm install linkerd-control-plane \
  --set-file identityTrustAnchorsPEM=... \
  --set-file identity.issuer.tls.crtPEM=... \
  --set-file identity.issuer.tls.keyPEM=... \
  --set policyValidator.externalSecret=true \
  --set-file policyValidator.injectCaFromSecret=linkerd-policy-validator-k8s-tls \
  --set proxyInjector.externalSecret=true \
  --set-file proxyInjector.injectCaFromSecret=linkerd-proxy-injector-k8s-tls \
  --set profileValidator.externalSecret=true \
  --set-file profileValidator.injectCaFromSecret=linkerd-sp-validator-k8s-tls \
  linkerd/linkerd-control-plane \
  -n linkerd
````

{{< note >}} When installing the `linkerd-control-plane` chart, you _must_
provide the issuer trust root and issuer credentials as described in
[Installing Linkerd with Helm](../install-helm/). {{< /note >}}

See
[Automatically Rotating Control Plane TLS Credentials](../automatically-rotating-control-plane-tls-credentials/)
for details on how to do something similar for control plane credentials.
