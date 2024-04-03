+++
title = "Automatically Rotating Control Plane TLS Credentials"
description = "Use cert-manager to automatically rotate control plane TLS credentials."
aliases = [ "use_external_certs" ]
+++

Linkerd's [automatic mTLS](../../features/automatic-mtls/) feature generates TLS
certificates for proxies and automatically rotates them without user
intervention. These certificates are derived from a _trust anchor_, which is
shared across clusters, and an _issuer certificate_, which is specific to the
cluster.

While Linkerd automatically rotates the per-proxy TLS certificates, it does not
rotate the issuer certificate. Linkerd's out-of-the-box installations generate
static self-signed certificates with a validity of one year but require manual
rotation by the user to prevent expiry. While this setup is convenient for quick
start testing, it's not advisable nor recommended for production environments.

{{< trylpt >}}

## Cert manager

[Cert-manager](https://github.com/jetstack/cert-manager) is a popular project
for making TLS credentials from external sources available to Kubernetes
clusters.

Cert-manager is very flexible. You can configure it to pull certificates from
secrets managemenet solutions such as [Vault](https://www.vaultproject.io). In
this guide, we'll focus on a self-sufficient setup: we will configure
cert-manager to act as an on-cluster
[CA](https://en.wikipedia.org/wiki/Certificate_authority) and have it re-issue
Linkerd's issuer certificate and private key on a periodic basis, derived from
the trust anchor. Additionally, we will use trust-manager create a trust bundle
which will allow Linkerd to verify the authenticity of certificates issued by
cert-manager.

### Cert manager as an on-cluster CA

As a first step,
[install cert-manager on your cluster](https://cert-manager.io/docs/installation/),
then
[install trust-manager](https://cert-manager.io/docs/trust/trust-manager/installation/)
and configure it to use "linkerd" as the
[trust namespace](https://cert-manager.io/docs/trust/trust-manager/installation/#trust-namespace).

Next, create the namespace that cert-manager will use to store its
Linkerd-related resources. For simplicity, we suggest reusing the default
Linkerd control plane namespace:

```bash
kubectl create namespace linkerd
```

#### Give cert-manager necessary RBAC permissions

By default cert-manager will only create certificate secrets in the namespace
where it is installed. Linkerd, however, requires the cert secrets to be created
in the linkerd namespace. To do this we will create a `ServiceAccount` for
cert-manager in the linkerd namespace with the required permissions.

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

#### Create the trust root ClusterIssuer

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

#### Create a trust root certificate

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

#### Create Linkerd identity issuer

Using the previously-generated trust root certificate, create a Linkerd identity
`Issuer`:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: linkerd-identity-issuer
  namespace: linkerd
spec:
  ca:
    secretName: linkerd-trust-anchor
EOF
```

#### Create a Certificate resource referencing the issuer

Next, create a Linkerd identity issuer certificate which will act as an
intermediary signing CA for all Linkerd mTLS proxy certificates:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-identity-issuer
  namespace: linkerd
spec:
  commonName: identity.linkerd.cluster.local
  dnsNames:
  - identity.linkerd.cluster.local
  isCA: true
  privateKey:
    algorithm: ECDSA
  usages:
    - cert sign
    - crl sign
    - server auth
    - client auth
  duration: 28h0m0s
  renewBefore: 25h0m0s
  issuerRef:
    name: linkerd-identity-issuer
    kind: Issuer
  privateKey:
    algorithm: ECDSA
  secretName: linkerd-identity-issuer
EOF
```

(In the YAML manifest above, the `duration` key instructs cert-manager to
consider certificates as valid for `48` hours and the `renewBefore` key
indicates that cert-manager will attempt to issue a new certificate `25` hours
before expiration of the current one. These values can be customized to your
liking.)

#### Create Linkerd trust bundle

Lastly, we will also need to create a trust bundle which will allow Linkerd's
identity controller to verify the authenticity of certificates issued by
cert-manager:

```bash
kubectl apply -f - <<EOF
apiVersion: trust.cert-manager.io/v1alpha1
kind: Bundle
metadata:
  name: linkerd-identity-trust-roots
  namespace: linkerd
spec:
  sources:
    - secret:
        name: "linkerd-trust-anchor"
        key: "ca.crt"
  target:
    configMap:
      key: "ca-bundle.crt"
EOF
```

## Summary & Validation

Below are the resources created for managing Linkerd identity certificates with
cert-manager:

- Namespace: `linkerd` (to store certificates and secrets)
- RBAC Permissions: ServiceAccount, Role, and RoleBinding in the `linkerd`
  namespace for cert-manager
- ClusterIssuer: `linkerd-trust-root-issuer` (self-signed ClusterIssuer)
- Certificate: `linkerd-trust-anchor` (in the `linkerd` namespace, referencing
  `linkerd-trust-root-issuer`)
- Issuer: `linkerd-identity-issuer` (to manage Linkerd identity certificates)
- Certificate: `linkerd-identity-issuer` (in the `linkerd` namespace, acting as
  an intermediary signing CA)
- Trust Bundle: `linkerd-identity-trust-roots` (to allow Linkerd's identity
  controller to verify certificate authenticity)

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

# Check Trust Bundle creation
kubectl get bundles -n linkerd
```

## Consuming cert-manager identity certificates

To have Linkerd consume cert-manager created certificates you will need to add
the following to your values file or pass them in as flags at runtime.

| Field                    | Value             |
| ------------------------ | ----------------- |
| `identity.externalCA`    | true              |
| `identity.issuer.scheme` | kubernetes.io/tls |

### Using these credentials with CLI installation

For CLI installation, the Linkerd control plane should be installed with the
`--identity-external-issuer` flag, which instructs Linkerd to read certificates
from the `linkerd-identity-issuer` secret. Whenever certificate and key stored
in the secret are updated, the `identity` service will automatically detect this
change and reload the new credentials.

Voila! We have set up automatic rotation of Linkerd's control plane TLS
credentials.

### Using these credentials with a Helm installation

For installing with Helm, first install the `linkerd-crds` chart:

```bash
helm install linkerd-crds -n linkerd --create-namespace linkerd/linkerd-crds
```

Then install the `linkerd-control-plane` chart:

```bash
helm install linkerd-control-plane -n linkerd \
  --set identity.externalCA=true \
  --set identity.issuer.scheme=kubernetes.io/tls \
  linkerd/linkerd-control-plane
```

Voila! We have set up automatic rotation of Linkerd's control plane TLS
credentials.

## Observing the update process

Once you have set up automatic rotation of Linkerd's control plane TLS
credentials, you can monitor the update process by checking the `IssuerUpdated`
events emitted by the service:

```bash
kubectl get events --field-selector reason=IssuerUpdated -n linkerd
```

## A note on third party cert management solutions

It is important to note that the mechanism that Linkerd provides for setting
issuer certificates and keys is also usable outside of cert-manager. Linkerd
will read the `linkerd-identity-issuer` Secret, and if it's of type
`kubernetes.io/tls`, will use the contents as its TLS credentials. This means
that any solution that is able to rotate TLS certificates by writing them to
this secret can be used to provide dynamic TLS certificate management.

You could generate that secret with a command such as:

```bash
kubectl create secret tls linkerd-identity-issuer --cert=issuer.crt --key=issuer.key --namespace=linkerd
```

Where `issuer.crt` and `issuer.key` would be the cert and private key of an
intermediary cert rooted at the trust root (`ca.crt`) referred above (check this
[guide](../generate-certificates/) to see how to generate them).

Note that the root cert (`ca.crt`) needs to be included in that Secret as well.
You can just edit the generated Secret and include the `ca.crt` field with the
contents of the file base64-encoded.

After setting up the `linkerd-identity-issuer` Secret, continue with the
following instructions to install and configure Linkerd to use it.

## See also

- [Automatically Rotating Webhook TLS Credentials](../automatically-rotating-webhook-tls-credentials/)
- [Manually rotating Linkerd's trust anchor credentials](../manually-rotating-control-plane-tls-credentials/)
