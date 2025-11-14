---
title: Automatically Rotating Control Plane TLS Credentials
description:
  Use cert-manager to automatically rotate control plane TLS credentials.
---

Linkerd's [automatic mTLS](../features/automatic-mtls/) feature generates TLS
certificates for proxies and automatically rotates them without user
intervention. These certificates are derived from a _trust anchor_, which is
shared across clusters, and an _issuer certificate_, which is specific to the
cluster.

While Linkerd automatically rotates the per-proxy TLS certificates, it does not
rotate the issuer certificate. In this doc, we'll describe how to set up
automatic rotation of the issuer certificate and its corresponding private key
using the cert-manager project.

{{< docs/production-note >}}

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
the trust anchor.

### Cert manager as an on-cluster CA

As a first step,
[install cert-manager on your cluster](https://cert-manager.io/docs/installation/).

Next, create the namespace that cert-manager will use to store its
Linkerd-related resources. For simplicity, we suggest reusing the default
Linkerd control plane namespace:

```bash
kubectl create namespace linkerd
```

#### Save the signing key pair as a Secret

Next, using the [`step`](https://smallstep.com/cli/) tool, create a signing key
pair and store it in a Kubernetes Secret in the namespace created above:

```bash
step certificate create root.linkerd.cluster.local ca.crt ca.key \
  --profile root-ca --no-password --insecure &&
  kubectl create secret tls \
    linkerd-trust-anchor \
    --cert=ca.crt \
    --key=ca.key \
    --namespace=linkerd
```

For a longer-lived trust anchor certificate, pass the `--not-after` argument to
the step command with the desired value (e.g. `--not-after=87600h`).

#### Create an Issuer referencing the secret

With the Secret in place, we can create a cert-manager "Issuer" resource that
references it:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: linkerd-trust-anchor
  namespace: linkerd
spec:
  ca:
    secretName: linkerd-trust-anchor
EOF
```

#### Create a Certificate resource referencing the Issuer

Finally, we can create a cert-manager "Certificate" resource which uses this
Issuer to generate the desired certificate:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-identity-issuer
  namespace: linkerd
spec:
  secretName: linkerd-identity-issuer
  duration: 48h
  renewBefore: 25h
  issuerRef:
    name: linkerd-trust-anchor
    kind: Issuer
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
EOF
```

(In the YAML manifest above, the `duration` key instructs cert-manager to
consider certificates as valid for `48` hours and the `renewBefore` key
indicates that cert-manager will attempt to issue a new certificate `25` hours
before expiration of the current one. These values can be customized to your
liking.)

At this point, cert-manager can now use this Certificate resource to obtain TLS
credentials, which will be stored in a secret named `linkerd-identity-issuer`.
To validate your newly-issued certificate, you can run:

```bash
kubectl get secret linkerd-identity-issuer -o yaml -n linkerd
```

Now we just need to inform Linkerd to consume these credentials.

## Using these credentials with CLI installation

For CLI installation, the Linkerd control plane should be installed with the
`--identity-external-issuer` flag, which instructs Linkerd to read certificates
from the `linkerd-identity-issuer` secret. Whenever certificate and key stored
in the secret are updated, the `identity` service will automatically detect this
change and reload the new credentials.

Voila! We have set up automatic rotation of Linkerd's control plane TLS
credentials.

## Using these credentials with a Helm installation

For installing with Helm, first install the `linkerd-crds` chart:

```bash
helm install linkerd-crds -n linkerd --create-namespace linkerd/linkerd-crds
```

Then install the `linkerd-control-plane` chart, setting the
`identityTrustAnchorsPEM` to the value of `ca.crt` in the
`linkerd-identity-issuer` Secret:

```bash
helm install linkerd-control-plane -n linkerd \
  --set-file identityTrustAnchorsPEM=ca.crt \
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
[guide](generate-certificates/) to see how to generate them).

Note that the root cert (`ca.crt`) needs to be included in that Secret as well.
You can just edit the generated Secret and include the `ca.crt` field with the
contents of the file base64-encoded.

After setting up the `linkerd-identity-issuer` Secret, continue with the
following instructions to install and configure Linkerd to use it.

## See also

- [Automatically Rotating Webhook TLS Credentials](automatically-rotating-webhook-tls-credentials/)
- [Manually rotating Linkerd's trust anchor credentials](manually-rotating-control-plane-tls-credentials/)
